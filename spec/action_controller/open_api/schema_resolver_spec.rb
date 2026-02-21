require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe ActionController::OpenApi::SchemaResolver do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = Pathname(dir)
      example.run
    end
  end

  def create_schema(relative_path, content)
    path = @tmpdir.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  describe "#resolve" do
    it "parses and returns a JSON schema" do
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      resolver = described_class.new

      result = resolver.resolve("items", "show", [@tmpdir])

      expect(result).to eq({ "summary" => "Show item" })
    end

    it "parses and returns a YAML schema" do
      create_schema("items/_show.schema.yaml", "summary: Show item\n")
      resolver = described_class.new

      result = resolver.resolve("items", "show", [@tmpdir])

      expect(result).to eq({ "summary" => "Show item" })
    end

    it "returns nil when no schema exists" do
      resolver = described_class.new

      expect(resolver.resolve("items", "show", [@tmpdir])).to be_nil
    end

    it "caches resolved schemas" do
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      resolver = described_class.new

      result1 = resolver.resolve("items", "show", [@tmpdir])
      result2 = resolver.resolve("items", "show", [@tmpdir])

      expect(result1).to equal(result2)
    end

    it "caches nil results" do
      resolver = described_class.new

      resolver.resolve("items", "show", [@tmpdir])
      # Create the file after first resolve — should still return nil due to cache
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      result = resolver.resolve("items", "show", [@tmpdir])

      expect(result).to be_nil
    end
  end
end
