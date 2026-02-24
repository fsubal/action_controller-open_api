module ActionController
  module OpenApi
    # Derives a Rails strong-parameters permit list from an OpenAPI schema.
    # Used by ControllerMethods#openapi_params.
    class ActionParameter
      def initialize(schema, defs: {})
        @schema = schema
        @defs = defs
      end

      # Returns an array suitable for ActionController::Parameters#permit.
      def permit_list
        list = []
        list.concat(permit_list_from_request_body) if @schema["requestBody"]
        list.concat(permit_list_from_query_parameters) if @schema["parameters"]
        list
      end

      private

      def permit_list_from_request_body
        content = @schema.dig("requestBody", "content") || {}
        body_schema = content.dig("application/json", "schema") ||
                      content.dig("multipart/form-data", "schema")
        return [] unless body_schema

        resolved = resolve_ref(body_schema)
        properties_to_permit_list(resolved["properties"] || {})
      end

      def permit_list_from_query_parameters
        Array(@schema["parameters"])
          .select { |p| p["in"] == "query" }
          .map { |p| p["name"].to_sym }
      end

      # Converts a JSON Schema `properties` hash into a Rails permit list.
      #
      # Scalars  → :key
      # Arrays   → { key: [] }          (array of scalars)
      #            { key: [nested...] }  (array of objects)
      # Objects  → { key: [nested...] }
      def properties_to_permit_list(properties)
        properties.flat_map do |name, prop_schema|
          resolved = resolve_ref(prop_schema)
          key = name.to_sym
          schema_to_permit(key, resolved)
        end
      end

      def schema_to_permit(key, resolved)
        case resolved["type"]
        when "object"
          nested = properties_to_permit_list(resolved["properties"] || {})
          [{ key => nested }]
        when "array"
          items = resolved["items"]
          if items
            resolved_items = resolve_ref(items)
            if resolved_items["type"] == "object"
              nested = properties_to_permit_list(resolved_items["properties"] || {})
              [{ key => nested }]
            else
              [{ key => [] }]
            end
          else
            [{ key => [] }]
          end
        else
          [key]
        end
      end

      def resolve_ref(schema)
        ref = schema["$ref"]
        return schema unless ref&.start_with?("#/$defs/")

        name = ref.delete_prefix("#/$defs/")
        @defs[name] || schema
      end
    end
  end
end
