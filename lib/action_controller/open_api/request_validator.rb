module ActionController
  module OpenApi
    class RequestValidator
      attr_reader :schema

      def initialize(schema)
        @schema = schema
      end

      def validate!(request)
        errors = []
        errors.concat(validate_parameters(schema, request)) if schema["parameters"]
        errors.concat(validate_request_body(schema, request)) if schema["requestBody"]

        raise RequestValidationError, errors if errors.any?
      end

      private

      def validate_parameters(schema, request)
        errors = []
        Array(schema["parameters"]).each do |param_schema|
          name = param_schema["name"]
          location = param_schema["in"]
          required = param_schema["required"]
          value = extract_param_value(request, name, location)

          if value.nil?
            if required
              errors << { "error" => "Missing required #{location} parameter: #{name}", "parameter" => name, "in" => location }
            end
            next
          end

          next unless param_schema["schema"]

          coerced = coerce_value(value, param_schema["schema"])
          param_errors = validate_with_json_schemer(coerced, param_schema["schema"])
          param_errors.each do |e|
            errors << { "error" => "Invalid #{location} parameter '#{name}': #{e["error"]}", "parameter" => name, "in" => location }
          end
        end
        errors
      end

      def extract_param_value(request, name, location)
        case location
        when "query"
          request.query_parameters[name]
        when "path"
          request.path_parameters[name.to_sym]&.to_s
        when "header"
          request.headers[name]
        when "cookie"
          request.cookie_jar[name]
        end
      end

      def coerce_value(value, schema)
        type = schema["type"]
        case type
        when "integer"
          Integer(value, exception: false) || value
        when "number"
          Float(value, exception: false) || value
        when "boolean"
          case value
          when "true" then true
          when "false" then false
          else value
          end
        when "array"
          Array(value)
        else
          value
        end
      end

      def validate_request_body(schema, request)
        request_body = schema["requestBody"]
        content = request_body["content"]
        return [] unless content

        json_schema = content.dig("application/json", "schema")
        return [] unless json_schema

        body = begin
          JSON.parse(request.body.read.presence || "{}")
        rescue JSON::ParserError => e
          return [{ "error" => "Invalid JSON in request body: #{e.message}" }]
        ensure
          request.body.rewind
        end

        validate_with_json_schemer(body, json_schema)
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
