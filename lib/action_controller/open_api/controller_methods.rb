module ActionController
  module OpenApi
    module ControllerMethods
      extend ActiveSupport::Concern

      included do
        class_attribute :_openapi_schema_resolver, instance_writer: false, default: SchemaResolver.new
      end

      private

      def validate_by_openapi_schema!
        RequestValidator.new(openapi_schema).validate!(request) if openapi_schema
        yield
        ResponseValidator.new(openapi_schema).validate!(response) if openapi_schema
      end

      def openapi_schema
        @openapi_schema ||= self.class._openapi_schema_resolver.resolve(
          controller_path,
          action_name,
          view_paths
        )
      end

      def openapi_params
        schema = openapi_schema
        raise MissingSchemaError.new(controller_path, action_name) unless schema

        defs = schema["$defs"] || {}
        permit_list = ActionParameter.new(schema, defs: defs).permit_list
        params.permit(*permit_list)
      end
    end
  end
end
