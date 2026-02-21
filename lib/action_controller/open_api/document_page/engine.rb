module ActionController
  module OpenApi
    module DocumentPage
      class Engine < ::Rails::Engine
        def self.find_root(from)
          Pathname.new(from)
        end

        isolate_namespace ActionController::OpenApi::DocumentPage
      end
    end
  end
end
