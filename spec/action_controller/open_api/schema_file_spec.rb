require "spec_helper"

RSpec.describe ActionController::OpenApi::SchemaFile do
  describe ".expected_path" do
    it "lists every extension a schema file may have" do
      expect(described_class.expected_path("admin/items", "show"))
        .to eq "app/views/admin/items/_show.schema.{json,jsonc,yaml,yml}"
    end
  end

  describe ".action_name" do
    it "strips the leading underscore and the schema extension" do
      expect(described_class.action_name("_show.schema.json")).to eq "show"
      expect(described_class.action_name("_show.schema.jsonc")).to eq "show"
      expect(described_class.action_name("_index.schema.yml")).to eq "index"
    end
  end
end
