require "spec_helper"

RSpec.describe ActionController::OpenApi::Error do
  it "is a StandardError" do
    expect(described_class.superclass).to eq StandardError
  end
end

RSpec.describe ActionController::OpenApi::RequestValidationError do
  it "is an ActionController::OpenApi::Error" do
    expect(described_class.superclass).to eq ActionController::OpenApi::Error
  end

  it "stores validation_errors and builds a message" do
    errors = [{ "error" => "missing param" }, { "error" => "bad type" }]
    ex = described_class.new(errors)

    expect(ex.validation_errors).to eq errors
    expect(ex.message).to eq "Request validation failed: missing param, bad type"
  end
end

RSpec.describe ActionController::OpenApi::ResponseValidationError do
  it "is an ActionController::OpenApi::Error" do
    expect(described_class.superclass).to eq ActionController::OpenApi::Error
  end

  it "stores validation_errors and builds a message" do
    errors = [{ "error" => "wrong type" }]
    ex = described_class.new(errors)

    expect(ex.validation_errors).to eq errors
    expect(ex.message).to eq "Response validation failed: wrong type"
  end
end
