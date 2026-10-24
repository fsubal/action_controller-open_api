module ActionController
  module OpenApi
    class SchemaFinder
      def initialize(view_paths)
        @view_paths = Array(view_paths).map { |p| Pathname(p.to_s) }
      end

      def find(controller_path, action_name)
        @view_paths.each do |view_path|
          SchemaFile::EXTENSIONS.each do |ext|
            path = view_path.join(controller_path, "_#{action_name}#{ext}")
            return path if path.exist?
          end
        end
        nil
      end

      def find_all
        results = []
        @view_paths.each do |view_path|
          next unless view_path.exist?

          Dir.glob(view_path.join("**", SchemaFile::GLOB)).each do |file|
            path = Pathname(file)
            relative = path.relative_path_from(view_path)
            controller_path = relative.dirname.to_s
            filename = relative.basename.to_s
            action_name = SchemaFile.action_name(filename)

            results << {
              path: path,
              controller_path: controller_path,
              action_name: action_name
            }
          end
        end
        results.uniq { |r| "#{r[:controller_path]}##{r[:action_name]}" }
      end
    end
  end
end
