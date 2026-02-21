require_relative "boot"

require "rails"
require "action_controller/railtie"

Bundler.require(*Rails.groups)
require "action_controller/open_api"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.hosts.clear
  end
end
