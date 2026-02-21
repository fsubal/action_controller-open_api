require "spec_helper"
require "stringio"
require "action_controller"
require "action_dispatch"

RSpec.describe ActionController::OpenApi::ControllerMethods do
  let(:schema) do
    {
      "parameters" => [
        { "name" => "id", "in" => "path", "required" => true, "schema" => { "type" => "integer" } }
      ],
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

  let(:resolver) { instance_double(ActionController::OpenApi::SchemaResolver) }
  let(:controller_class) do
    klass = Class.new do
      include ActionController::OpenApi::ControllerMethods

      attr_accessor :controller_path_value, :action_name_value, :view_paths_value,
                    :request, :response

      def controller_path
        @controller_path_value
      end

      def action_name
        @action_name_value
      end

      def view_paths
        @view_paths_value
      end

      public :validate_by_openapi_schema!
    end
    klass
  end

  let(:controller) { controller_class.new }

  before do
    controller.controller_path_value = "items"
    controller.action_name_value = "show"
    controller.view_paths_value = ["/app/views"]
    controller_class._openapi_schema_resolver = resolver
  end

  describe "#validate_by_openapi_schema!" do
    context "when no schema exists" do
      before do
        allow(resolver).to receive(:resolve).and_return(nil)
      end

      it "yields without validation" do
        called = false
        controller.validate_by_openapi_schema! { called = true }

        expect(called).to be true
      end
    end

    context "when schema exists" do
      before do
        allow(resolver).to receive(:resolve).and_return(schema)
      end

      it "validates request, yields, then validates response" do
        body_io = StringIO.new("")
        controller.request = double("request",
          query_parameters: {}, path_parameters: { id: "1" },
          headers: {}, cookie_jar: {}, body: body_io
        )
        controller.response = double("response",
          status: 200, body: '{"id": 1, "name": "Test"}'
        )

        call_order = []
        allow_any_instance_of(ActionController::OpenApi::RequestValidator)
          .to receive(:validate!) { call_order << :request }
        allow_any_instance_of(ActionController::OpenApi::ResponseValidator)
          .to receive(:validate!) { call_order << :response }

        controller.validate_by_openapi_schema! { call_order << :yield }

        expect(call_order).to eq [:request, :yield, :response]
      end

      it "raises RequestValidationError before yielding" do
        body_io = StringIO.new("")
        controller.request = double("request",
          query_parameters: {}, path_parameters: {},
          headers: {}, cookie_jar: {}, body: body_io
        )

        yielded = false
        expect {
          controller.validate_by_openapi_schema! { yielded = true }
        }.to raise_error(ActionController::OpenApi::RequestValidationError)

        expect(yielded).to be false
      end

      it "raises ResponseValidationError after yielding" do
        body_io = StringIO.new("")
        controller.request = double("request",
          query_parameters: {}, path_parameters: { id: "1" },
          headers: {}, cookie_jar: {}, body: body_io
        )
        controller.response = double("response",
          status: 200, body: '{"bad": "data"}'
        )

        yielded = false
        expect {
          controller.validate_by_openapi_schema! { yielded = true }
        }.to raise_error(ActionController::OpenApi::ResponseValidationError)

        expect(yielded).to be true
      end
    end
  end
end
