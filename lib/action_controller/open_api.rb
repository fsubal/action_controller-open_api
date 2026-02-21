require "action_controller/open_api/version"
require "action_controller/open_api/railtie" if defined?(Rails::Railtie)

module ActionController
  module OpenApi
    class Error < StandardError; end

    # Your code goes here...
  end
end
