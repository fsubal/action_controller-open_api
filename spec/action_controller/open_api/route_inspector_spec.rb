require "spec_helper"
require "action_dispatch"
require "action_dispatch/routing"

RSpec.describe ActionController::OpenApi::RouteInspector do
  def build_routes(&block)
    route_set = ActionDispatch::Routing::RouteSet.new
    route_set.draw(&block)
    route_set
  end

  def with_rails_routes(route_set)
    rails_app = double("rails_app", routes: route_set)
    allow(Rails).to receive(:application).and_return(rails_app)
  end

  before do
    stub_const("Rails", Class.new) unless defined?(Rails)
  end

  describe "#find_route" do
    it "finds a simple GET route" do
      routes = build_routes do
        get "/items", to: "items#index"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "index")

      expect(result[:path]).to eq "/items"
      expect(result[:method]).to eq "get"
    end

    it "converts path parameters to OpenAPI format" do
      routes = build_routes do
        get "/items/:id", to: "items#show"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "show")

      expect(result[:path]).to eq "/items/{id}"
      expect(result[:method]).to eq "get"
    end

    it "strips format segments" do
      routes = build_routes do
        get "/items/:id", to: "items#show"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "show")

      expect(result[:path]).not_to include("format")
    end

    it "handles POST routes" do
      routes = build_routes do
        post "/items", to: "items#create"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "create")

      expect(result[:path]).to eq "/items"
      expect(result[:method]).to eq "post"
    end

    it "handles PATCH routes" do
      routes = build_routes do
        patch "/items/:id", to: "items#update"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "update")

      expect(result[:method]).to eq "patch"
    end

    it "handles DELETE routes" do
      routes = build_routes do
        delete "/items/:id", to: "items#destroy"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "destroy")

      expect(result[:method]).to eq "delete"
    end

    it "returns nil for unknown routes" do
      routes = build_routes do
        get "/items", to: "items#index"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      expect(inspector.find_route("users", "index")).to be_nil
    end

    it "handles namespaced controllers" do
      routes = build_routes do
        namespace :admin do
          get "/items", to: "items#index"
        end
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("admin/items", "index")

      expect(result[:path]).to eq "/admin/items"
      expect(result[:method]).to eq "get"
    end

    it "handles multiple path parameters" do
      routes = build_routes do
        get "/users/:user_id/items/:id", to: "items#show"
      end
      with_rails_routes(routes)
      inspector = described_class.new

      result = inspector.find_route("items", "show")

      expect(result[:path]).to eq "/users/{user_id}/items/{id}"
    end
  end
end
