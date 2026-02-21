module ActionController
  module OpenApi
    module DocumentPage
      class DocumentsController < ::ActionController::Base
        def show; end

        def schema
          builder = ::ActionController::OpenApi::DocumentBuilder.new(
            view_paths: view_paths,
            info: ::ActionController::OpenApi.configuration.info
          )

          render json: builder.as_json
        end
      end
    end
  end
end
