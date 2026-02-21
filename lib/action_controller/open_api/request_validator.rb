module ActionController
  module OpenApi
    class RequestValidator
      attr_reader :schema

      def initialize(schema)
        @schema = schema
        @defs = schema["$defs"] || {}
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

          resolved = resolve_schema(param_schema["schema"])
          coerced = coerce_value(value, resolved)
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

      def resolve_schema(schema)
        ref = schema["$ref"]
        return schema unless ref&.start_with?("#/$defs/")

        name = ref.delete_prefix("#/$defs/")
        @defs[name] || schema
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

        if (json_schema = content.dig("application/json", "schema"))
          validate_json_body(request, json_schema)
        elsif (form_schema = content.dig("multipart/form-data", "schema"))
          validate_form_body(request, form_schema)
        else
          []
        end
      end

      def validate_json_body(request, json_schema)
        raw = request.body.read
        request.body.rewind
        body = JSON.parse(raw.empty? ? "{}" : raw)
        validate_with_json_schemer(body, json_schema)
      rescue JSON::ParserError => e
        [{ "error" => "Invalid JSON in request body: #{e.message}" }]
      end

      def validate_form_body(request, form_schema)
        params = request.request_parameters.transform_values do |v|
          uploaded_file?(v) ? "" : v
        end
        validate_with_json_schemer(params, form_schema)
      end

      def uploaded_file?(value)
        value.respond_to?(:original_filename)
      end

      def validate_with_json_schemer(data, schema)
        schemer_schema = @defs.empty? ? schema : schema.merge("$defs" => @defs.merge(schema["$defs"] || {}))
        schemer = JSONSchemer.schema(schemer_schema)
        schemer.validate(data).map do |error|
          { "error" => error["error"] || error["type"], "details" => error }
        end
      end
    end
  end
end
