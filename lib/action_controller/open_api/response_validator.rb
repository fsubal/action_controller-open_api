module ActionController
  module OpenApi
    class ResponseValidator
      def initialize
      end

      def validate!(schema, response)
        responses = schema["responses"]
        return unless responses

        status = response.status.to_s
        response_schema = find_response_schema(responses, status)
        return unless response_schema

        content = response_schema["content"]
        return unless content

        json_schema = content.dig("application/json", "schema")
        return unless json_schema

        body = begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          raise ResponseValidationError, [{ "error" => "Invalid JSON in response body: #{e.message}" }]
        end

        errors = validate_with_json_schemer(body, json_schema)
        raise ResponseValidationError, errors if errors.any?
      end

      private

      def find_response_schema(responses, status)
        responses[status] ||
          responses[wildcard_status(status)] ||
          responses["default"]
      end

      def wildcard_status(status)
        "#{status[0]}XX"
      end

      def validate_with_json_schemer(data, schema)
        schemer = JSONSchemer.schema(schema)
        schemer.validate(data).map do |error|
          { "error" => error["error"] || error["type"], "details" => error }
        end
      end
    end
  end
end
