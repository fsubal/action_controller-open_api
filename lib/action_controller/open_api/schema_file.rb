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
          JSON.parse(strip_jsonc(content))
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

      # Tokens after which a comma separates nothing, so it is not a trailing
      # comma to drop but an error to keep for JSON.parse (`{,}`, `[1,,]`)
      NO_VALUE_BEFORE = [nil, "{", "[", ",", ":"].freeze

      # Turns JSONC into JSON: drops `//` and `/* */` comments and trailing
      # commas, leaving string contents untouched. Comments become spaces so
      # parse error offsets still point into the original text.
      def strip_jsonc(text)
        out = +""
        i = 0
        pending_comma = nil
        # The last character of JSON syntax written, ignoring whitespace and comments
        last_token = nil
        while i < text.length
          char = text[i]
          if char == '"'
            finish = string_end(text, i)
            out << flush(pending_comma) << text[i...finish]
            pending_comma = nil
            last_token = '"'
            i = finish
          elsif text[i, 2] == "//"
            finish = text.index("\n", i) || text.length
            (pending_comma || out) << (" " * (finish - i))
            i = finish
          elsif text[i, 2] == "/*"
            finish = text.index("*/", i + 2)
            raise JSON::ParserError, "unterminated comment in JSONC" unless finish

            (pending_comma || out) << text[i...(finish + 2)].gsub(/[^\n]/, " ")
            i = finish + 2
          elsif char == ","
            out << flush(pending_comma)
            pending_comma = nil
            if NO_VALUE_BEFORE.include?(last_token)
              out << char
            else
              pending_comma = +","
            end
            last_token = ","
            i += 1
          elsif pending_comma && char.match?(/\s/)
            pending_comma << char
            i += 1
          elsif pending_comma && ["}", "]"].include?(char)
            # a trailing comma: keep its whitespace, drop the comma
            out << pending_comma.sub(",", " ") << char
            pending_comma = nil
            last_token = char
            i += 1
          else
            out << flush(pending_comma) << char
            pending_comma = nil
            last_token = char unless char.match?(/\s/)
            i += 1
          end
        end
        out << flush(pending_comma)
      end

      def string_end(text, start)
        i = start + 1
        while i < text.length
          case text[i]
          when "\\" then i += 2
          when '"' then return i + 1
          else i += 1
          end
        end
        text.length
      end

      def flush(pending_comma)
        pending_comma || ""
      end

      private_class_method :string_end, :flush
    end
  end
end
