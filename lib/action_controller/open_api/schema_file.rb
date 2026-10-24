module ActionController
  module OpenApi
    # The schema file formats: JSON, JSONC (JSON with comments and trailing
    # commas, e.g. for TypeScript tooling that cannot claim `.json` files)
    # and YAML. Earlier extensions win when several exist for one action.
    module SchemaFile
      EXTENSIONS = %w[.schema.json .schema.jsonc .schema.yaml .schema.yml].freeze
      GLOB = "_*.schema.{json,jsonc,yaml,yml}".freeze
      EXTENSION_PATTERN = /\.schema\.(?:jsonc?|ya?ml)\z/

      module_function

      def parse(path)
        content = path.read
        case path.extname
        when ".json"
          JSON.parse(content)
        when ".jsonc"
          JSONC.parse(content)
        when ".yaml", ".yml"
          YAML.safe_load(content, permitted_classes: [Symbol])
        end
      end

      # ("items", "show") => "app/views/items/_show.schema.{json,jsonc,yaml,yml}"
      def expected_path(controller_path, action_name)
        extensions = EXTENSIONS.map { |ext| ext.delete_prefix(".schema.") }.join(",")
        "app/views/#{controller_path}/_#{action_name}.schema.{#{extensions}}"
      end

      # "_show.schema.jsonc" => "show"
      def action_name(filename)
        filename.sub(/\A_/, "").sub(EXTENSION_PATTERN, "")
      end
    end
  end
end
