require "spec_helper"

RSpec.describe ActionController::OpenApi::ActionParameter do
  def permit_list(schema, defs: {})
    described_class.new(schema, defs: defs).permit_list
  end

  describe "#permit_list" do
    context "with requestBody (application/json)" do
      it "permits scalar properties" do
        schema = {
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => {
                    "name" => { "type" => "string" },
                    "age" => { "type" => "integer" }
                  }
                }
              }
            }
          }
        }

        expect(permit_list(schema)).to contain_exactly(:name, :age)
      end

      it "permits nested object properties" do
        schema = {
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => {
                    "address" => {
                      "type" => "object",
                      "properties" => {
                        "city" => { "type" => "string" },
                        "zip" => { "type" => "string" }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        expect(permit_list(schema)).to eq [{ address: [:city, :zip] }]
      end

      it "permits array of scalars" do
        schema = {
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => {
                    "tags" => { "type" => "array", "items" => { "type" => "string" } }
                  }
                }
              }
            }
          }
        }

        expect(permit_list(schema)).to eq [{ tags: [] }]
      end

      it "permits array of objects" do
        schema = {
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => {
                    "items" => {
                      "type" => "array",
                      "items" => {
                        "type" => "object",
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
          }
        }

        expect(permit_list(schema)).to eq [{ items: [:id, :name] }]
      end

      it "resolves $ref from $defs" do
        defs = {
          "Item" => {
            "type" => "object",
            "properties" => {
              "id" => { "type" => "integer" },
              "name" => { "type" => "string" }
            }
          }
        }
        schema = {
          "$defs" => defs,
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => { "$ref" => "#/$defs/Item" }
              }
            }
          }
        }

        expect(permit_list(schema, defs: defs)).to contain_exactly(:id, :name)
      end
    end

    context "with requestBody (multipart/form-data)" do
      it "permits form fields from multipart schema" do
        schema = {
          "requestBody" => {
            "content" => {
              "multipart/form-data" => {
                "schema" => {
                  "type" => "object",
                  "properties" => {
                    "title" => { "type" => "string" },
                    "attachment" => { "type" => "string", "format" => "binary" }
                  }
                }
              }
            }
          }
        }

        expect(permit_list(schema)).to contain_exactly(:title, :attachment)
      end
    end

    context "with query parameters" do
      it "permits query parameters by name" do
        schema = {
          "parameters" => [
            { "name" => "page", "in" => "query", "schema" => { "type" => "integer" } },
            { "name" => "per_page", "in" => "query", "schema" => { "type" => "integer" } }
          ]
        }

        expect(permit_list(schema)).to contain_exactly(:page, :per_page)
      end

      it "includes path parameters and excludes header and cookie parameters" do
        schema = {
          "parameters" => [
            { "name" => "id", "in" => "path", "schema" => { "type" => "integer" } },
            { "name" => "X-Api-Key", "in" => "header", "schema" => { "type" => "string" } },
            { "name" => "session", "in" => "cookie", "schema" => { "type" => "string" } },
            { "name" => "q", "in" => "query", "schema" => { "type" => "string" } }
          ]
        }

        expect(permit_list(schema)).to contain_exactly(:id, :q)
      end
    end

    context "with both requestBody and query parameters" do
      it "combines both" do
        schema = {
          "parameters" => [
            { "name" => "locale", "in" => "query", "schema" => { "type" => "string" } }
          ],
          "requestBody" => {
            "content" => {
              "application/json" => {
                "schema" => {
                  "type" => "object",
                  "properties" => { "name" => { "type" => "string" } }
                }
              }
            }
          }
        }

        expect(permit_list(schema)).to contain_exactly(:name, :locale)
      end
    end

    context "with no requestBody or parameters" do
      it "returns an empty list" do
        schema = { "responses" => {} }
        expect(permit_list(schema)).to eq []
      end
    end
  end
end
