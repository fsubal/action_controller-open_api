require "spec_helper"
require "tmpdir"
require "fileutils"
require "action_dispatch"
require "action_dispatch/routing"

RSpec.describe ActionController::OpenApi::DocumentBuilder do
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

  def with_rails_routes(&block)
    route_set = ActionDispatch::Routing::RouteSet.new
    route_set.draw(&block)
    rails_app = double("rails_app", routes: route_set)
    stub_const("Rails", Class.new) unless defined?(Rails)
    allow(Rails).to receive(:application).and_return(rails_app)
  end

  describe "#build" do
    it "returns a valid OpenAPI 3.0.3 document structure" do
      with_rails_routes { }
      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      expect(doc["openapi"]).to eq "3.0.3"
      expect(doc["info"]).to be_a Hash
      expect(doc["paths"]).to be_a Hash
    end

    it "uses default info when none provided" do
      with_rails_routes { }
      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      expect(doc["info"]["title"]).to eq "API Documentation"
      expect(doc["info"]["version"]).to eq "1.0.0"
    end

    it "uses custom info when provided" do
      with_rails_routes { }
      info = { "title" => "My API", "version" => "2.0.0" }
      builder = described_class.new(view_paths: [@tmpdir], info: info)
      doc = builder.build

      expect(doc["info"]).to eq info
    end

    it "maps schema files to OpenAPI paths" do
      schema = {
        "summary" => "List items",
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => { "type" => "array" }
              }
            }
          }
        }
      }
      create_schema("items/_index.schema.json", JSON.generate(schema))

      with_rails_routes do
        get "/items", to: "items#index"
      end

      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      expect(doc["paths"]["/items"]).to be_a Hash
      expect(doc["paths"]["/items"]["get"]["operationId"]).to eq "items#index"
      expect(doc["paths"]["/items"]["get"]["summary"]).to eq "List items"
      expect(doc["paths"]["/items"]["get"]["responses"]).to eq schema["responses"]
    end

    it "generates operationId from controller_path and action_name" do
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      with_rails_routes do
        get "/items/:id", to: "items#show"
      end

      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      expect(doc["paths"]["/items/{id}"]["get"]["operationId"]).to eq "items#show"
    end

    it "includes multiple operations on the same path" do
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      create_schema("items/_update.schema.json", '{"summary": "Update item"}')
      with_rails_routes do
        get "/items/:id", to: "items#show"
        patch "/items/:id", to: "items#update"
      end

      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      path = doc["paths"]["/items/{id}"]
      expect(path["get"]["operationId"]).to eq "items#show"
      expect(path["patch"]["operationId"]).to eq "items#update"
    end

    it "skips schemas without matching routes" do
      create_schema("items/_show.schema.json", '{"summary": "Show item"}')
      with_rails_routes { }

      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      expect(doc["paths"]).to be_empty
    end

    it "includes parameters, requestBody, description, and tags" do
      schema = {
        "summary" => "Create item",
        "description" => "Creates a new item",
        "tags" => ["items"],
        "parameters" => [{ "name" => "X-Api-Key", "in" => "header" }],
        "requestBody" => { "content" => {} },
        "responses" => {}
      }
      create_schema("items/_create.schema.json", JSON.generate(schema))
      with_rails_routes do
        post "/items", to: "items#create"
      end

      builder = described_class.new(view_paths: [@tmpdir])
      doc = builder.build

      operation = doc["paths"]["/items"]["post"]
      expect(operation["description"]).to eq "Creates a new item"
      expect(operation["tags"]).to eq ["items"]
      expect(operation["parameters"]).to eq schema["parameters"]
      expect(operation["requestBody"]).to eq schema["requestBody"]
    end
  end

  describe "#to_json" do
    it "returns a JSON string" do
      with_rails_routes { }
      builder = described_class.new(view_paths: [@tmpdir])
      json = builder.to_json

      parsed = JSON.parse(json)
      expect(parsed["openapi"]).to eq "3.0.3"
    end
  end
end
