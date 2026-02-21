require "spec_helper"

RSpec.describe ActionController::OpenApi::ResponseValidator do
  let(:validator) { described_class.new }

  def mock_response(status:, body:)
    double("response", status: status, body: body)
  end

  describe "#validate!" do
    it "passes when response matches exact status schema" do
      schema = {
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "required" => ["id"],
                  "properties" => { "id" => { "type" => "integer" } }
                }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: '{"id": 1}')

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "raises when response doesn't match schema" do
      schema = {
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "required" => ["id"],
                  "properties" => { "id" => { "type" => "integer" } }
                }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: '{"name": "test"}')

      expect { described_class.new(schema).validate!(response) }.to raise_error(
        ActionController::OpenApi::ResponseValidationError
      )
    end

    it "falls back to wildcard status (2XX)" do
      schema = {
        "responses" => {
          "2XX" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "required" => ["id"],
                  "properties" => { "id" => { "type" => "integer" } }
                }
              }
            }
          }
        }
      }
      response = mock_response(status: 201, body: '{"id": 1}')

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "falls back to default response schema" do
      schema = {
        "responses" => {
          "default" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => { "error" => { "type" => "string" } }
                }
              }
            }
          }
        }
      }
      response = mock_response(status: 500, body: '{"error": "internal"}')

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "raises on invalid JSON response body" do
      schema = {
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
      response = mock_response(status: 200, body: "not json")

      expect { described_class.new(schema).validate!(response) }.to raise_error(
        ActionController::OpenApi::ResponseValidationError
      ) do |error|
        expect(error.validation_errors.first["error"]).to include("Invalid JSON")
      end
    end

    it "skips validation when no responses key in schema" do
      schema = { "summary" => "test" }
      response = mock_response(status: 200, body: "anything")

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "skips validation when status is not matched" do
      schema = {
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
      response = mock_response(status: 404, body: "not found")

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "skips validation for non-JSON content types" do
      schema = {
        "responses" => {
          "200" => {
            "content" => {
              "text/html" => {
                "schema" => { "type" => "string" }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: "<html></html>")

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
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

    it "resolves $ref in response body schema" do
      schema = {
        "$defs" => { "Item" => item_def },
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => { "$ref" => "#/$defs/Item" }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: '{"id": 1, "name": "widget"}')

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end

    it "raises when data is invalid against referenced type" do
      schema = {
        "$defs" => { "Item" => item_def },
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => { "$ref" => "#/$defs/Item" }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: '{"id": "not-an-integer", "name": "widget"}')

      expect { described_class.new(schema).validate!(response) }.to raise_error(
        ActionController::OpenApi::ResponseValidationError
      )
    end

    it "does not break schemas without $defs" do
      schema = {
        "responses" => {
          "200" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "required" => ["id"],
                  "properties" => { "id" => { "type" => "integer" } }
                }
              }
            }
          }
        }
      }
      response = mock_response(status: 200, body: '{"id": 1}')

      expect { described_class.new(schema).validate!(response) }.not_to raise_error
    end
  end
end
