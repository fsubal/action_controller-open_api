module ActionController
  module OpenApi
    class DocumentBuilder
      def initialize(view_paths:, info: nil)
        @view_paths = view_paths
        @info = info || default_info
      end

      def as_json
        {
          "openapi" => "3.0.3",
          "info" => @info,
          "paths" => build_paths
        }
      end

      def to_json
        JSON.pretty_generate(as_json)
      end

      private

      def default_info
        {
          "title" => "API Documentation",
          "version" => "1.0.0"
        }
      end

      def build_paths
        finder = SchemaFinder.new(@view_paths)
        inspector = RouteInspector.new
        paths = {}

        finder.find_all.each do |entry|
          route = inspector.find_route(entry[:controller_path], entry[:action_name])
          next unless route

          schema = parse_schema(entry[:path])
          next unless schema

          operation = build_operation(schema, entry[:controller_path], entry[:action_name])

          paths[route[:path]] ||= {}
          paths[route[:path]][route[:method]] = operation
        end

        paths
      end

      def parse_schema(path)
        content = path.read
        case path.extname
        when ".json"
          JSON.parse(content)
        when ".yaml", ".yml"
          YAML.safe_load(content, permitted_classes: [Symbol])
        end
      end

      def build_operation(schema, controller_path, action_name)
        operation = {}
        operation["operationId"] = "#{controller_path}##{action_name}"
        operation["summary"] = schema["summary"] if schema["summary"]
        operation["description"] = schema["description"] if schema["description"]
        operation["parameters"] = schema["parameters"] if schema["parameters"]
        operation["requestBody"] = schema["requestBody"] if schema["requestBody"]
        operation["responses"] = schema["responses"] if schema["responses"]
        operation["tags"] = schema["tags"] if schema["tags"]
        operation
      end
    end
  end
end
