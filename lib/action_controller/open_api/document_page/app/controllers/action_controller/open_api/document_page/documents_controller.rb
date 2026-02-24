module ActionController
  module OpenApi
    module DocumentPage
      class DocumentsController < ::ActionController::Base
        skip_forgery_protection only: :redoc_js

        REDOC_JS_PATH = File.expand_path(
          "../../../../assets/javascripts/redoc.standalone.js",
          __dir__
        )

        def show; end

        def redoc_js
          send_file REDOC_JS_PATH, type: "application/javascript", disposition: :inline
        end

        def schema
          builder = ::ActionController::OpenApi::DocumentBuilder.new(
            view_paths: view_paths,
            info: ::ActionController::OpenApi.configuration.info
          )

          render json: builder.as_json
        end

        private

        def openapi_redoc_js_url
          source = ::ActionController::OpenApi.configuration.redoc_js_source
          case source
          when :vendored then redoc_js_path
          when :cdn      then ::ActionController::OpenApi::CDN_REDOC_JS_URL
          else                source.to_s
          end
        end
        helper_method :openapi_redoc_js_url
      end
    end
  end
end
