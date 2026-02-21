require "action_controller/open_api/test_helper"

RSpec::Matchers.define :conform_to_openapi_schema do
  match do |response|
    @response = response
    begin
      helper = Object.new
      helper.extend(ActionController::OpenApi::TestHelper)
      helper.define_singleton_method(:response) { @response }
      helper.instance_variable_set(:@response, response)
      helper.assert_response_conforms_to_openapi_schema
      true
    rescue StandardError => e
      @failure_message = e.message
      false
    end
  end

  failure_message do
    @failure_message
  end
end

RSpec.configure do |config|
  config.include ActionController::OpenApi::TestHelper, type: :request
end
