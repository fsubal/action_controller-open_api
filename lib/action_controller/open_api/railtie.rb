module ActionController
  module OpenApi
    class Railtie < Rails::Railtie
      railtie_name :action_controller_open_api

      initializer "action_controller_open_api.initialize" do
        ActiveSupport.on_load(:action_controller) do
          # Include OpenApi functionality into ActionController::Base
          # extend ActionController::OpenApi::ClassMethods
          # include ActionController::OpenApi::InstanceMethods
        end
      end
    end
  end
end
