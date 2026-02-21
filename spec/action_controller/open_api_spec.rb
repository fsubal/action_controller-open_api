require "spec_helper"

RSpec.describe ActionController::OpenApi do
  it "has a version number" do
    expect(ActionController::OpenApi::VERSION).not_to be nil
  end
end
