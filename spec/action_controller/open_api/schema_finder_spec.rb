require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe ActionController::OpenApi::SchemaFinder do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = Pathname(dir)
      example.run
    end
  end

  def create_file(relative_path)
    path = @tmpdir.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, "{}")
    path
  end

  describe "#find" do
    it "finds a .schema.json file" do
      create_file("items/_show.schema.json")
      finder = described_class.new([@tmpdir])

      result = finder.find("items", "show")

      expect(result).to eq @tmpdir.join("items/_show.schema.json")
    end

    it "finds a .schema.yaml file" do
      create_file("items/_show.schema.yaml")
      finder = described_class.new([@tmpdir])

      result = finder.find("items", "show")

      expect(result).to eq @tmpdir.join("items/_show.schema.yaml")
    end

    it "finds a .schema.yml file" do
      create_file("items/_index.schema.yml")
      finder = described_class.new([@tmpdir])

      result = finder.find("items", "index")

      expect(result).to eq @tmpdir.join("items/_index.schema.yml")
    end

    it "prefers .schema.json over .schema.yaml" do
      create_file("items/_show.schema.json")
      create_file("items/_show.schema.yaml")
      finder = described_class.new([@tmpdir])

      result = finder.find("items", "show")

      expect(result).to eq @tmpdir.join("items/_show.schema.json")
    end

    it "returns nil when no schema file exists" do
      finder = described_class.new([@tmpdir])

      expect(finder.find("items", "show")).to be_nil
    end

    it "searches multiple view_paths and returns the first match" do
      Dir.mktmpdir do |dir2|
        tmpdir2 = Pathname(dir2)
        create_file("items/_show.schema.json")
        path2 = tmpdir2.join("items/_show.schema.json")
        FileUtils.mkdir_p(path2.dirname)
        File.write(path2, "{}")

        finder = described_class.new([@tmpdir, tmpdir2])
        result = finder.find("items", "show")

        expect(result).to eq @tmpdir.join("items/_show.schema.json")
      end
    end

    it "handles nested controller paths" do
      create_file("admin/items/_show.schema.json")
      finder = described_class.new([@tmpdir])

      result = finder.find("admin/items", "show")

      expect(result).to eq @tmpdir.join("admin/items/_show.schema.json")
    end
  end

  describe "#find_all" do
    it "returns all schema files across view paths" do
      create_file("items/_show.schema.json")
      create_file("items/_index.schema.json")
      create_file("users/_create.schema.yaml")
      finder = described_class.new([@tmpdir])

      results = finder.find_all

      expect(results.length).to eq 3
      paths = results.map { |r| "#{r[:controller_path]}##{r[:action_name]}" }
      expect(paths).to contain_exactly("items#show", "items#index", "users#create")
    end

    it "deduplicates schemas across multiple view paths" do
      Dir.mktmpdir do |dir2|
        tmpdir2 = Pathname(dir2)
        create_file("items/_show.schema.json")
        path2 = tmpdir2.join("items/_show.schema.json")
        FileUtils.mkdir_p(path2.dirname)
        File.write(path2, "{}")

        finder = described_class.new([@tmpdir, tmpdir2])
        results = finder.find_all

        expect(results.length).to eq 1
      end
    end

    it "returns empty array when no schemas exist" do
      finder = described_class.new([@tmpdir])

      expect(finder.find_all).to eq []
    end

    it "skips non-existent view paths" do
      finder = described_class.new([Pathname("/nonexistent/path")])

      expect(finder.find_all).to eq []
    end
  end
end
