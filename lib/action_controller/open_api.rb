require "json"
require "yaml"
require "pathname"
require "json_schemer"
require "active_support/concern"

require "action_controller/open_api/version"
require "action_controller/open_api/errors"
require "action_controller/open_api/schema_finder"
require "action_controller/open_api/schema_resolver"
require "action_controller/open_api/route_inspector"
require "action_controller/open_api/request_validator"
require "action_controller/open_api/response_validator"
require "action_controller/open_api/action_parameter"
require "action_controller/open_api/controller_methods"
require "action_controller/open_api/document_builder"
require "action_controller/open_api/railtie" if defined?(Rails::Railtie)

module ActionController
  module OpenApi
    CDN_REDOC_JS_URL = "https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"

    class Configuration
      attr_accessor :info, :redoc_js_source

      def initialize
        @info = nil
        @redoc_js_source = :vendored
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end
  end
end
