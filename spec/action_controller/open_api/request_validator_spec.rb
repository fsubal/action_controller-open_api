require "spec_helper"
require "stringio"

RSpec.describe ActionController::OpenApi::RequestValidator do
  let(:validator) { described_class.new }

  def mock_request(query: {}, path: {}, headers: {}, body: nil)
    req = double("request")
    allow(req).to receive(:query_parameters).and_return(query)
    allow(req).to receive(:path_parameters).and_return(path)
    allow(req).to receive(:headers).and_return(headers)
    allow(req).to receive(:cookie_jar).and_return({})
    if body
      string_io = StringIO.new(body)
      allow(req).to receive(:body).and_return(string_io)
    end
    req
  end

  describe "parameter validation" do
    it "passes when required parameter is present and valid" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: { "id" => "42" })

      expect { validator.validate!(schema, request) }.not_to raise_error
    end

    it "raises when required parameter is missing" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: {})

      expect { validator.validate!(schema, request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      ) do |error|
        expect(error.validation_errors.first["error"]).to include("Missing required")
      end
    end

    it "skips validation for optional missing parameters" do
      schema = {
        "parameters" => [
          { "name" => "page", "in" => "query", "required" => false, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: {})

      expect { validator.validate!(schema, request) }.not_to raise_error
    end

    it "validates path parameters" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "path", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(path: { id: "42" })

      expect { validator.validate!(schema, request) }.not_to raise_error
    end

    it "raises when parameter value doesn't match schema type" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: { "id" => "not_a_number" })

      expect { validator.validate!(schema, request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      )
    end

    it "coerces boolean string values" do
      schema = {
        "parameters" => [
          { "name" => "active", "in" => "query", "required" => true, "schema" => { "type" => "boolean" } }
        ]
      }
      request = mock_request(query: { "active" => "true" })

      expect { validator.validate!(schema, request) }.not_to raise_error
    end

    it "validates header parameters" do
      schema = {
        "parameters" => [
          { "name" => "X-Api-Key", "in" => "header", "required" => true, "schema" => { "type" => "string" } }
        ]
      }
      request = mock_request(headers: { "X-Api-Key" => "secret" })

      expect { validator.validate!(schema, request) }.not_to raise_error
    end
  end

  describe "request body validation" do
    it "passes when body matches schema" do
      schema = {
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => {
                "type" => "object",
                "required" => ["name"],
                "properties" => {
                  "name" => { "type" => "string" }
                }
              }
            }
          }
        }
      }
      request = mock_request(body: '{"name": "test"}')

      expect { validator.validate!(schema, request) }.not_to raise_error
    end

    it "raises when body doesn't match schema" do
      schema = {
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => {
                "type" => "object",
                "required" => ["name"],
                "properties" => {
                  "name" => { "type" => "string" }
                }
              }
            }
          }
        }
      }
      request = mock_request(body: '{"age": 25}')

      expect { validator.validate!(schema, request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      )
    end

    it "raises when body contains invalid JSON" do
      schema = {
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => { "type" => "object" }
            }
          }
        }
      }
      request = mock_request(body: "not json")

      expect { validator.validate!(schema, request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      ) do |error|
        expect(error.validation_errors.first["error"]).to include("Invalid JSON")
      end
    end

    it "rewinds request body after reading" do
      schema = {
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => { "type" => "object" }
            }
          }
        }
      }
      body_io = StringIO.new('{"name": "test"}')
      request = double("request",
        query_parameters: {}, path_parameters: {},
        headers: {}, cookie_jar: {}, body: body_io
      )

      validator.validate!(schema, request)

      expect(body_io.read).to eq '{"name": "test"}'
    end
  end

  describe "no validation needed" do
    it "passes when schema has no parameters or requestBody" do
      schema = { "responses" => {} }
      request = mock_request

      expect { validator.validate!(schema, request) }.not_to raise_error
    end
  end
end
