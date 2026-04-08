require "action_controller/open_api/test_helper/assertsion"

module ActionController
  module OpenApi
    module TestHelper
      def assert_response_conforms_to_openapi_schema
        TestHelper::Assertion.new(response).call
      end
    end
  end
end
