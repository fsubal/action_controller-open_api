# ActionController::OpenApi

A Rails plugin that generates OpenAPI documentation from schema files placed alongside your views, and validates requests/responses against those schemas in development.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'action_controller-open_api'
```

And then execute:

```bash
bundle install
```

## Usage

### 1. Define schema files in `app/views`

Place `.schema.json` (or `.schema.yaml`) files next to your view templates. The file name must follow the `_<action>.schema.json` convention:

```
app/
  views/
    items/
      _index.schema.json
      _show.schema.json
      _create.schema.json
      show.json.jbuilder      # your regular view template
```

Each schema file describes the **operation** for that controller action — parameters, request body, and responses — following the [OpenAPI 3.0 Operation Object](https://swagger.io/docs/specification/v3_0/paths-and-operations/) format. You don't need to specify the path or HTTP method; those are inferred from Rails routes.

```json
{
  "summary": "Get an item",
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": { "type": "integer" }
    }
  ],
  "responses": {
    "200": {
      "description": "A single item",
      "content": {
        "application/json": {
          "schema": {
            "type": "object",
            "required": ["id", "name"],
            "properties": {
              "id": { "type": "integer" },
              "name": { "type": "string" }
            }
          }
        }
      }
    }
  }
}
```

For actions with a request body (e.g. `create`, `update`):

```json
{
  "summary": "Create an item",
  "requestBody": {
    "required": true,
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "required": ["name"],
          "properties": {
            "name": { "type": "string" }
          }
        }
      }
    }
  },
  "responses": {
    "201": {
      "description": "Created item",
      "content": {
        "application/json": {
          "schema": {
            "type": "object",
            "required": ["id", "name"],
            "properties": {
              "id": { "type": "integer" },
              "name": { "type": "string" }
            }
          }
        }
      }
    }
  }
}
```

### 2. Enable request/response validation

The `validate_by_openapi_schema!` method is automatically available in all controllers. Use it as an `around_action`:

```ruby
class ItemsController < ApplicationController
  # Validate all actions
  around_action :validate_by_openapi_schema!

  # Or validate specific actions, only in development
  around_action :validate_by_openapi_schema!, only: [:show, :create], if: -> { Rails.env.development? }

  def show
    item = Item.find(params[:id])
    render json: item
  end

  def create
    item = Item.create!(item_params)
    render json: item, status: :created
  end
end
```

When validation fails:

- **Invalid request** (bad parameters or request body) — raises `ActionController::OpenApi::RequestValidationError`
- **Invalid response** (response body doesn't match schema) — raises `ActionController::OpenApi::ResponseValidationError`

Both inherit from `ActionController::OpenApi::Error` (which inherits from `StandardError`). You can rescue them in your controller:

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActionController::OpenApi::RequestValidationError do |e|
    render json: { errors: e.validation_errors }, status: :bad_request
  end

  rescue_from ActionController::OpenApi::ResponseValidationError do |e|
    render json: { errors: e.validation_errors }, status: :internal_server_error
  end
end
```

### 3. Configure

Set the OpenAPI document's info section in an initializer:

```ruby
# config/initializers/openapi.rb
ActionController::OpenApi.configure do |config|
  config.info = {
    "title" => "My API",
    "version" => "1.0.0",
    "description" => "My application API"
  }
end
```

## Document Generation

All `.schema.json` files are collected and combined with route information to produce a complete OpenAPI 3.0.3 document.

### Mountable Engine (development)

Mount the built-in engine to serve interactive API documentation via [Redoc](https://github.com/Redocly/redoc):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount ActionController::OpenApi::DocumentPage::Engine, at: "/openapi"
end
```

This provides:

- `GET /openapi` — Redoc UI
- `GET /openapi/openapi.json` — OpenAPI JSON document

### Rake Task (static generation)

Generate static files for production hosting:

```bash
bin/rails action_controller_openapi:precompile
```

This outputs:

- `public/openapi/openapi.json` — The OpenAPI document
- `public/openapi/index.html` — Standalone Redoc HTML page with the spec embedded

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

A dummy Rails app is available at `test/dummy/` for manual testing:

```bash
cd test/dummy
bundle exec rails server
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fsubal/action_controller-open_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
