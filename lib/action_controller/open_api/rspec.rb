require "action_controller/open_api/test_helper/assertsion"

RSpec::Matchers.define :conform_to_openapi_schema do
  match do |response|
    @response = response

    begin
      TestHelper::Assertion.new(response).call
      true
    rescue StandardError => e
      @failure_message = e.message
      false
    end
  end

  failure_message { @failure_message }
end

RSpec.configure do |config|
  config.include ActionController::OpenApi::TestHelper, type: :request
end
