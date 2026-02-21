require_relative "lib/action_controller/open_api/version"

Gem::Specification.new do |spec|
  spec.name        = "action_controller-open_api"
  spec.version     = ActionController::OpenApi::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["your.email@example.com"]
  spec.homepage    = "https://github.com/yourusername/action_controller-open_api"
  spec.summary     = "OpenAPI integration for ActionController"
  spec.description = "A Rails plugin that provides OpenAPI/Swagger documentation generation for ActionController"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  spec.add_dependency "railties", ">= 6.0"
  spec.add_dependency "actionpack", ">= 6.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rails"
end
