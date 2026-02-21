module ActionController
  module OpenApi
    class SchemaResolver
      def initialize
        @cache = {}
      end

      def resolve(controller_path, action_name, view_paths)
        cache_key = "#{controller_path}##{action_name}"
        return @cache[cache_key] if @cache.key?(cache_key)

        finder = SchemaFinder.new(view_paths)
        path = finder.find(controller_path, action_name)
        @cache[cache_key] = path ? parse(path) : nil
      end

      private

      def parse(path)
        content = path.read
        case path.extname
        when ".json"
          JSON.parse(content)
        when ".yaml", ".yml"
          YAML.safe_load(content, permitted_classes: [Symbol])
        end
      end
    end
  end
end
