require "action_controller/open_api/document_page/engine"

module ActionController
  module OpenApi
    class Railtie < Rails::Railtie
      railtie_name :action_controller_open_api

      initializer "action_controller_open_api.initialize" do
        ActiveSupport.on_load(:action_controller) do
          include ActionController::OpenApi::ControllerMethods
        end
      end

      rake_tasks do
        load "action_controller/open_api/tasks/action_controller_openapi.rake"
      end
    end
  end
end
