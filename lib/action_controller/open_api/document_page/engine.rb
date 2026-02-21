module ActionController
  module OpenApi
    module DocumentPage
      class Engine < ::Rails::Engine
        isolate_namespace ActionController::OpenApi::DocumentPage

        initializer "action_controller_open_api.document_page.assets" do |app|
          app.config.assets.precompile += %w[] if app.config.respond_to?(:assets)
        end
      end
    end
  end
end
