require "spec_helper"

RSpec.describe ActionController::OpenApi::Configuration do
  describe "#info" do
    it "defaults to nil" do
      config = described_class.new
      expect(config.info).to be_nil
    end

    it "can be set" do
      config = described_class.new
      config.info = { "title" => "My API", "version" => "1.0" }
      expect(config.info).to eq({ "title" => "My API", "version" => "1.0" })
    end
  end

  describe "#redoc_js_source" do
    it "defaults to :vendored" do
      config = described_class.new
      expect(config.redoc_js_source).to eq(:vendored)
    end

    it "can be set to :cdn" do
      config = described_class.new
      config.redoc_js_source = :cdn
      expect(config.redoc_js_source).to eq(:cdn)
    end

    it "can be set to a custom URL string" do
      config = described_class.new
      config.redoc_js_source = "/assets/redoc.standalone.js"
      expect(config.redoc_js_source).to eq("/assets/redoc.standalone.js")
    end
  end
end

RSpec.describe ActionController::OpenApi do
  describe ".configure" do
    after do
      # Reset configuration between tests
      ActionController::OpenApi.instance_variable_set(:@configuration, nil)
    end

    it "yields configuration" do
      ActionController::OpenApi.configure do |config|
        config.info = { "title" => "Test" }
      end

      expect(ActionController::OpenApi.configuration.info).to eq({ "title" => "Test" })
    end
  end

  describe ".configuration" do
    after do
      ActionController::OpenApi.instance_variable_set(:@configuration, nil)
    end

    it "returns a Configuration instance" do
      expect(ActionController::OpenApi.configuration).to be_a ActionController::OpenApi::Configuration
    end

    it "memoizes the configuration" do
      config1 = ActionController::OpenApi.configuration
      config2 = ActionController::OpenApi.configuration
      expect(config1).to equal(config2)
    end
  end
end
