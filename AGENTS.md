# AGENTS.md

## Project overview

`action_controller-open_api` is a Rails gem that lets you define OpenAPI operation schemas as `.schema.json` (or `.schema.yaml`) files alongside your view templates in `app/views/`, then validates requests and responses against those schemas at runtime.

## Commands

- `bundle exec rspec` — run all tests (69 specs)
- `rake dummy:server` — start the dummy Rails app at `test/dummy/`
- `rake dummy:console` — open a Rails console in the dummy app
- `rake dummy:rails[routes]` — run arbitrary Rails commands in the dummy app

## Architecture

```
lib/action_controller/open_api/
├── railtie.rb              # Hooks into Rails; includes ControllerMethods
├── controller_methods.rb   # around_action :validate_by_openapi_schema!
├── schema_finder.rb        # Discovers .schema.{json,yaml,yml} in view paths
├── schema_resolver.rb      # Parses and caches schema files
├── request_validator.rb    # Validates params + request body against schema
├── response_validator.rb   # Validates response body against schema
├── route_inspector.rb      # Maps controller#action → OpenAPI path + method
├── document_builder.rb     # Assembles full OpenAPI 3.0.3 document
├── errors.rb               # RequestValidationError, ResponseValidationError
├── document_page/          # Mountable Rails Engine serving Redoc UI
└── tasks/                  # Rake task for static OpenAPI + Redoc generation
```

Key flow: `ControllerMethods#validate_by_openapi_schema!` resolves the schema via `SchemaResolver` → `SchemaFinder`, then runs `RequestValidator#validate!` before yielding and `ResponseValidator#validate!` after.

## Test conventions

- RSpec with `expect` syntax only (monkey patching disabled)
- Specs mirror `lib/` structure under `spec/action_controller/open_api/`
- No Rails boot in specs — tests use plain Ruby doubles and mocks
- Temp directories (`Dir.mktmpdir`) for filesystem-dependent tests (e.g. `SchemaFinder`)
- `.rspec` flags: `--require spec_helper --color --format documentation`

## Schema file convention

Schema files are placed next to view templates with a leading underscore:

```
app/views/items/
    _show.json.jbuilder     # normal view
    _show.schema.json       # OpenAPI operation object (without path/method)
```

The path and HTTP method are inferred from Rails routes, so schema files only contain the OpenAPI Operation Object (parameters, requestBody, responses, etc.).

## Dependencies

- **Runtime**: `railties >= 6.0`, `actionpack >= 6.0`, `json_schemer >= 2.0`
- **Dev**: `rake`, `rspec`, `rails`, `puma`
- **Ruby**: `>= 2.7.0` (gemspec), CI tests 3.1/3.2/3.3
- **Toolchain**: `mise` with Ruby 3.3

## Dummy app

`test/dummy/` is a minimal Rails app with an `ItemsController` (index/show/create) and matching schema files. It mounts the OpenAPI document page engine at `/openapi`. Use it for manual testing and integration verification.
