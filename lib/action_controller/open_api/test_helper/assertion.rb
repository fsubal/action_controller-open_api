require "action_controller/open_api"

module ActionController
  module OpenApi
    module TestHelper
      class Assertion
        attr_reader :request, :response

        def initialize(response)
          @response = response
          @request = response.request
        end

        def call
          unless controller_path && action_name
            fail!(
              "Could not determine controller/action from the request. " \
              "Make sure the request has been dispatched through Rails routing."
            )
          end

          unless schema
            fail!(
              "No OpenAPI schema found for #{controller_path}##{action_name}. " \
              "Expected file at app/views/#{controller_path}/_#{action_name}.schema.json"
            )
          end

          ResponseValidator.new(schema).validate!(response)
        rescue ResponseValidationError => e
          message = "Response does not conform to OpenAPI schema for #{controller_path}##{action_name}:\n"

          e.validation_errors.each do |error|
            message += "  - #{error["error"] || error[:error]}\n"
          end

          fail!(message)
        end

        private

        def schema
          @schema ||= SchemaResolver.new.resolve(controller_path, action_name, view_paths)
        end

        def controller_path
          @controller_path ||= request.path_parameters[:controller]
        end

        def action_name
          @action_name ||= request.path_parameters[:action]
        end

        def view_paths
          controller_class = request.controller_class

          if controller_class.respond_to?(:view_paths)
            controller_class.view_paths.map(&:to_path)
          else
            Rails.application.config.paths["app/views"].existent
          end
        rescue NameError
          Rails.application.config.paths["app/views"].existent
        end

        def fail!(message)
          raise message unless defined?(Minitest::Assertion)

          raise Minitest::Assertion, message
        end
      end
    end
  end
end
