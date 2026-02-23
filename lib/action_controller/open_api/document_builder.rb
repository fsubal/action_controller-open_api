module ActionController
  module OpenApi
    class DocumentBuilder
      OPENAPI_VERSION = "3.0.3"

      def initialize(view_paths:, info: nil, paths: nil)
        @view_paths = view_paths
        @info = info || default_info
        @paths = paths || build_paths
      end

      def as_json
        doc = { "openapi" => OPENAPI_VERSION, "info" => @info, "paths" => @paths }
        doc["components"] = { "schemas" => @collected_defs } if @collected_defs&.any?
        doc
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
        @collected_defs = {}

        finder.find_all.each do |entry|
          route = inspector.find_route(entry[:controller_path], entry[:action_name])
          next unless route

          schema = parse_schema(entry[:path])
          next unless schema

          (schema["$defs"] || {}).each do |name, defn|
            if @collected_defs.key?(name)
              warn "[action_controller-open_api] Duplicate $defs key '#{name}' from " \
                   "#{entry[:controller_path]}##{entry[:action_name]}; overwriting"
            end
            @collected_defs[name] = defn
          end

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
        rewrite_refs(operation)
      end

      def rewrite_refs(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), h|
            h[k] = if k == "$ref" && v.is_a?(String) && v.start_with?("#/$defs/")
                     v.sub("#/$defs/", "#/components/schemas/")
                   else
                     rewrite_refs(v)
                   end
          end
        when Array then obj.map { |v| rewrite_refs(v) }
        else obj
        end
      end
    end
  end
end
