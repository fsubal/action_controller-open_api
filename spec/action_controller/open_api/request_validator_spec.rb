require "spec_helper"
require "stringio"

RSpec.describe ActionController::OpenApi::RequestValidator do
  def mock_request(query: {}, path: {}, headers: {}, body: nil, form: nil)
    req = double("request")
    allow(req).to receive(:query_parameters).and_return(query)
    allow(req).to receive(:path_parameters).and_return(path)
    allow(req).to receive(:headers).and_return(headers)
    allow(req).to receive(:cookie_jar).and_return({})
    if body
      string_io = StringIO.new(body)
      allow(req).to receive(:body).and_return(string_io)
    end
    allow(req).to receive(:request_parameters).and_return(form || {})
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

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "raises when required parameter is missing" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: {})

      expect { described_class.new(schema).validate!(request) }.to raise_error(
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

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "validates path parameters" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "path", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(path: { id: "42" })

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "raises when parameter value doesn't match schema type" do
      schema = {
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "type" => "integer" } }
        ]
      }
      request = mock_request(query: { "id" => "not_a_number" })

      expect { described_class.new(schema).validate!(request) }.to raise_error(
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

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "validates header parameters" do
      schema = {
        "parameters" => [
          { "name" => "X-Api-Key", "in" => "header", "required" => true, "schema" => { "type" => "string" } }
        ]
      }
      request = mock_request(headers: { "X-Api-Key" => "secret" })

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
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

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
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

      expect { described_class.new(schema).validate!(request) }.to raise_error(
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

      expect { described_class.new(schema).validate!(request) }.to raise_error(
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

      described_class.new(schema).validate!(request)

      expect(body_io.read).to eq '{"name": "test"}'
    end
  end

  describe "multipart/form-data request body validation" do
    let(:form_schema) do
      {
        "requestBody" => {
          "content" => {
            "multipart/form-data" => {
              "schema" => {
                "type" => "object",
                "required" => ["title"],
                "properties" => {
                  "title" => { "type" => "string" }
                }
              }
            }
          }
        }
      }
    end

    it "passes when all required form fields are present" do
      request = mock_request(form: { "title" => "hello" })
      expect { described_class.new(form_schema).validate!(request) }.not_to raise_error
    end

    it "raises when a required text field is missing" do
      request = mock_request(form: {})
      expect { described_class.new(form_schema).validate!(request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      )
    end

    it "passes when a required file field (format: binary) is present" do
      schema = {
        "requestBody" => {
          "content" => {
            "multipart/form-data" => {
              "schema" => {
                "type" => "object",
                "required" => ["attachment"],
                "properties" => {
                  "attachment" => { "type" => "string", "format" => "binary" }
                }
              }
            }
          }
        }
      }
      uploaded_file = double("uploaded_file", original_filename: "file.pdf")
      request = mock_request(form: { "attachment" => uploaded_file })
      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "raises when a required file field is missing" do
      schema = {
        "requestBody" => {
          "content" => {
            "multipart/form-data" => {
              "schema" => {
                "type" => "object",
                "required" => ["attachment"],
                "properties" => {
                  "attachment" => { "type" => "string", "format" => "binary" }
                }
              }
            }
          }
        }
      }
      request = mock_request(form: {})
      expect { described_class.new(schema).validate!(request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      )
    end

    it "passes when schema has only application/json content (existing behaviour unaffected)" do
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
      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end
  end

  describe "no validation needed" do
    it "passes when schema has no parameters or requestBody" do
      schema = { "responses" => {} }
      request = mock_request

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end
  end

  describe "$defs / $ref resolution" do
    let(:item_def) do
      {
        "type" => "object",
        "required" => ["id", "name"],
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        }
      }
    end

    it "resolves $ref in requestBody schema" do
      schema = {
        "$defs" => { "Item" => item_def },
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => { "$ref" => "#/$defs/Item" }
            }
          }
        }
      }
      request = mock_request(body: '{"id": 1, "name": "foo"}')

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "resolves $ref in parameter schema" do
      schema = {
        "$defs" => {
          "ItemId" => { "type" => "integer", "minimum" => 1 }
        },
        "parameters" => [
          { "name" => "id", "in" => "query", "required" => true, "schema" => { "$ref" => "#/$defs/ItemId" } }
        ]
      }
      request = mock_request(query: { "id" => "42" })

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end

    it "raises when referenced type matches but data is invalid" do
      schema = {
        "$defs" => { "Item" => item_def },
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => { "$ref" => "#/$defs/Item" }
            }
          }
        }
      }
      request = mock_request(body: '{"id": "not-an-integer", "name": "foo"}')

      expect { described_class.new(schema).validate!(request) }.to raise_error(
        ActionController::OpenApi::RequestValidationError
      )
    end

    it "does not break schemas without $defs" do
      schema = {
        "requestBody" => {
          "content" => {
            "application/json" => {
              "schema" => {
                "type" => "object",
                "required" => ["name"],
                "properties" => { "name" => { "type" => "string" } }
              }
            }
          }
        }
      }
      request = mock_request(body: '{"name": "test"}')

      expect { described_class.new(schema).validate!(request) }.not_to raise_error
    end
  end
end
