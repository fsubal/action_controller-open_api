module ActionController
  module OpenApi
    class RouteInspector
      def initialize
        @routes = Rails.application.routes.routes
      end

      def find_route(controller_path, action_name)
        route = @routes.detect do |r|
          requirements = r.requirements
          requirements[:controller] == controller_path && requirements[:action] == action_name
        end

        return nil unless route

        path = route.path.spec.to_s
        path = convert_to_openapi_path(path)

        verb = extract_verb(route)
        return nil unless verb

        { path: path, method: verb }
      end

      private

      def convert_to_openapi_path(path)
        path = path.gsub(/\(\.?:?\w+\)/, "")
        path = path.gsub(/:(\w+)/, '{\1}')
        path = path.chomp("/") if path.length > 1
        path
      end

      def extract_verb(route)
        verb = route.verb
        case verb
        when String
          verb.downcase.presence
        when Regexp
          verb.source.gsub(/[\^$]/, "").downcase.presence
        else
          verb.to_s.downcase.presence
        end
      end
    end
  end
end
