require "action_controller/open_api"

module ActionController
  module OpenApi
    module TestHelper
      def assert_response_conforms_to_openapi_schema
        path_parameters = response.request.path_parameters
        controller_path = path_parameters[:controller]
        action_name = path_parameters[:action]

        unless controller_path && action_name
          raise assertion_error_class,
            "Could not determine controller/action from the request. " \
            "Make sure the request has been dispatched through Rails routing."
        end

        view_paths = resolve_view_paths
        resolver = SchemaResolver.new
        schema = resolver.resolve(controller_path, action_name, view_paths)

        unless schema
          raise assertion_error_class,
            "No OpenAPI schema found for #{controller_path}##{action_name}. " \
            "Expected file at app/views/#{controller_path}/_#{action_name}.schema.json"
        end

        begin
          ResponseValidator.new(schema).validate!(response)
        rescue ResponseValidationError => e
          message = "Response does not conform to OpenAPI schema for #{controller_path}##{action_name}:\n"
          e.validation_errors.each do |error|
            message += "  - #{error["error"] || error[:error]}\n"
          end
          raise assertion_error_class, message
        end
      end

      private

      def resolve_view_paths
        controller_class = response.request.controller_class
        if controller_class.respond_to?(:view_paths)
          controller_class.view_paths.map(&:to_path)
        else
          Rails.application.config.paths["app/views"].existent
        end
      rescue NameError
        Rails.application.config.paths["app/views"].existent
      end

      def assertion_error_class
        defined?(Minitest::Assertion) ? Minitest::Assertion : RuntimeError
      end
    end
  end
end
