require "spec_helper"
require "tmpdir"
require "action_controller/open_api/test_helper"

RSpec.describe ActionController::OpenApi::TestHelper do
  let(:helper) do
    Object.new.tap { |o| o.extend(described_class) }
  end

  let(:schema) do
    {
      "responses" => {
        "200" => {
          "content" => {
            "application/json" => {
              "schema" => {
                "type" => "object",
                "required" => ["id", "name"],
                "properties" => {
                  "id" => { "type" => "integer" },
                  "name" => { "type" => "string" }
                }
              }
            }
          }
        }
      }
    }
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = Pathname(dir)
      example.run
    end
  end

  def create_schema(controller_path, action_name, content)
    path = @tmpdir.join(controller_path)
    path.mkpath
    file = path.join("_#{action_name}.schema.json")
    file.write(JSON.generate(content))
  end

  def mock_response(status:, body:, controller_path:, action_name:)
    request = double("request",
      path_parameters: { controller: controller_path, action: action_name }
    )
    controller_class = double("controller_class")
    allow(controller_class).to receive(:respond_to?).with(:view_paths).and_return(true)
    allow(controller_class).to receive(:view_paths).and_return(
      [double("view_path", to_path: @tmpdir.to_s)]
    )
    allow(request).to receive(:controller_class).and_return(controller_class)
    double("response", status: status, body: body, request: request)
  end

  def set_response(resp)
    helper.define_singleton_method(:response) { resp }
  end

  describe "#assert_response_conforms_to_openapi_schema" do
    it "passes when response conforms to schema" do
      create_schema("items", "show", schema)
      resp = mock_response(status: 200, body: '{"id": 1, "name": "Test"}', controller_path: "items", action_name: "show")
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.not_to raise_error
    end

    it "raises when response violates schema" do
      create_schema("items", "show", schema)
      resp = mock_response(status: 200, body: '{"id": "not_an_integer"}', controller_path: "items", action_name: "show")
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.to raise_error(RuntimeError) do |error|
        expect(error.message).to include("items#show")
        expect(error.message).to include("Response does not conform to OpenAPI schema")
      end
    end

    it "raises with helpful message when no schema file exists" do
      resp = mock_response(status: 200, body: '{"id": 1}', controller_path: "items", action_name: "show")
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.to raise_error(RuntimeError) do |error|
        expect(error.message).to include("No OpenAPI schema found for items#show")
        expect(error.message).to include("app/views/items/_show.schema.json")
      end
    end

    it "raises when path_parameters are missing" do
      request = double("request", path_parameters: {})
      controller_class = double("controller_class")
      allow(request).to receive(:controller_class).and_return(controller_class)
      resp = double("response", status: 200, body: "{}", request: request)
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.to raise_error(RuntimeError) do |error|
        expect(error.message).to include("Could not determine controller/action")
      end
    end

    it "raises on invalid JSON body" do
      schema_with_json = {
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => { "type" => "object" }
              }
            }
          }
        }
      }
      create_schema("items", "show", schema_with_json)
      resp = mock_response(status: 200, body: "not valid json", controller_path: "items", action_name: "show")
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.to raise_error(RuntimeError) do |error|
        expect(error.message).to include("Invalid JSON")
      end
    end

    it "passes when schema has no responses key" do
      create_schema("items", "show", { "summary" => "Get an item" })
      resp = mock_response(status: 200, body: "anything", controller_path: "items", action_name: "show")
      set_response(resp)

      expect { helper.assert_response_conforms_to_openapi_schema }.not_to raise_error
    end
  end
end
