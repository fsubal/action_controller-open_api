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
        @cache[cache_key] = path ? SchemaFile.parse(path) : nil
      end
    end
  end
end
