module ActionController
  module OpenApi
    module ControllerMethods
      extend ActiveSupport::Concern

      included do
        class_attribute :_openapi_schema_resolver, instance_writer: false, default: SchemaResolver.new
      end

      private

      def validate_by_openapi_schema!
        schema = self.class._openapi_schema_resolver.resolve(
          controller_path,
          action_name,
          view_paths
        )

        unless schema
          yield
          return
        end

        RequestValidator.new.validate!(schema, request)
        yield
        ResponseValidator.new.validate!(schema, response)
      end
    end
  end
end
