module ActionController
  module OpenApi
    class Error < StandardError; end

    class RequestValidationError < Error
      attr_reader :validation_errors

      def initialize(validation_errors)
        @validation_errors = validation_errors
        super("Request validation failed: #{validation_errors.map { |e| e["error"] || e[:error] }.join(", ")}")
      end
    end

    class MissingSchemaError < Error
      def initialize(controller_path, action_name)
        super("No OpenAPI schema found for #{controller_path}##{action_name}. " \
              "openapi_params requires a schema file at " \
              "app/views/#{controller_path}/_#{action_name}.schema.json")
      end
    end

    class ResponseValidationError < Error
      attr_reader :validation_errors

      def initialize(validation_errors)
        @validation_errors = validation_errors
        super("Response validation failed: #{validation_errors.map { |e| e["error"] || e[:error] }.join(", ")}")
      end
    end
  end
end
