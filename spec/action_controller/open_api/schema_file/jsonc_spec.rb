require "spec_helper"

RSpec.describe ActionController::OpenApi::SchemaFile::JSONC do
  describe ".parse" do
    it "drops line and block comments" do
      text = <<~JSONC
        {
          // a line comment
          "a": 1, /* a block
          comment */ "b": [2]
        }
      JSONC

      expect(described_class.parse(text)).to eq({ "a" => 1, "b" => [2] })
    end

    it "drops trailing commas in objects and arrays, even before a comment" do
      text = <<~JSONC
        {
          "a": [1, 2,],
          "b": { "c": 3, }, // trailing
        }
      JSONC

      expect(described_class.parse(text)).to eq({ "a" => [1, 2], "b" => { "c" => 3 } })
    end

    it "keeps commas that follow no value, so malformed JSONC still fails to parse" do
      ["{,}", "[,]", "[ /* c */ , ]", "[1,,]", '{"a": 1,,}', '{"a":,}'].each do |text|
        expect { described_class.parse(text) }.to raise_error(JSON::ParserError), "expected #{text.inspect} to be rejected"
      end
    end

    it "leaves comment-like and comma-like text inside strings alone" do
      text = '{ "url": "https://example.com/*x*/", "s": "a,}", "q": "say \\"//hi\\"," }'

      expect(described_class.parse(text)).to eq({ "url" => "https://example.com/*x*/", "s" => "a,}", "q" => 'say "//hi",' })
    end
  end

  describe ".strip_jsonc" do
    it "keeps offsets so parse errors point into the original text" do
      text = "{ /* c */ \"a\": 1,\n  oops }"

      expect(described_class.strip_jsonc(text).length).to eq text.length
    end

    it "keeps plain JSON as it is" do
      text = '{"a": [1, {"b": null}], "c": "d"}'

      expect(described_class.strip_jsonc(text)).to eq text
    end

    it "raises on an unterminated block comment" do
      expect { described_class.strip_jsonc('{ "a": 1 /* }') }.to raise_error(JSON::ParserError)
    end
  end
end
