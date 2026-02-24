namespace :action_controller_openapi do
  namespace :schema do
    desc "Extract response JSON Schema from a schema file (e.g. action_controller_openapi:schema:response[items/show] or [items/show,200])"
    task :response, [:action_path, :status] => :environment do |_t, args|
      action_path = args[:action_path]
      abort "Usage: rake action_controller_openapi:schema:response[controller/action] or [controller/action,STATUS]" unless action_path

      parts = action_path.split("/")
      action_name = parts.pop
      controller_path = parts.join("/")

      view_paths = ActionController::Base.view_paths.map(&:to_path)
      resolver = ActionController::OpenApi::SchemaResolver.new
      schema = resolver.resolve(controller_path, action_name, view_paths)
      abort "No schema found for #{controller_path}/#{action_name}" unless schema

      responses = schema["responses"]
      abort "No responses defined in schema for #{controller_path}/#{action_name}" unless responses

      status = args[:status] || responses.keys.first
      response_schema = responses[status]
      abort "No response defined for status #{status}" unless response_schema

      json_schema = response_schema.dig("content", "application/json", "schema")
      abort "No application/json schema defined for status #{status}" unless json_schema

      $stdout.puts JSON.pretty_generate(json_schema)
    end

    desc "Extract requestBody JSON Schema from a schema file (e.g. action_controller_openapi:schema:request_body[items/create])"
    task :request_body, [:action_path] => :environment do |_t, args|
      action_path = args[:action_path]
      abort "Usage: rake action_controller_openapi:schema:request_body[controller/action]" unless action_path

      parts = action_path.split("/")
      action_name = parts.pop
      controller_path = parts.join("/")

      view_paths = ActionController::Base.view_paths.map(&:to_path)
      resolver = ActionController::OpenApi::SchemaResolver.new
      schema = resolver.resolve(controller_path, action_name, view_paths)
      abort "No schema found for #{controller_path}/#{action_name}" unless schema

      json_schema = schema.dig("requestBody", "content", "application/json", "schema")
      abort "No requestBody application/json schema defined for #{controller_path}/#{action_name}" unless json_schema

      $stdout.puts JSON.pretty_generate(json_schema)
    end
  end

  desc "Inspect the full OpenAPI Operation for a controller action (e.g. action_controller_openapi:operation[items/show])"
  task :operation, [:action_path] => :environment do |_t, args|
    action_path = args[:action_path]
    abort "Usage: rake action_controller_openapi:operation[controller/action]" unless action_path

    parts = action_path.split("/")
    action_name = parts.pop
    controller_path = parts.join("/")

    view_paths = ActionController::Base.view_paths.map(&:to_path)
    resolver = ActionController::OpenApi::SchemaResolver.new
    schema = resolver.resolve(controller_path, action_name, view_paths)
    abort "No schema found for #{controller_path}/#{action_name}" unless schema

    route = ActionController::OpenApi::RouteInspector.new.find_route(controller_path, action_name)
    abort "No route found for #{controller_path}##{action_name}" unless route

    operation = {
      route[:path] => {
        route[:method] => schema
      }
    }

    $stdout.puts JSON.pretty_generate(operation)
  end

  desc "Precompile OpenAPI document and Redoc HTML to public/openapi/"
  task precompile: :environment do
    require "fileutils"

    output_dir = Rails.root.join("public", "openapi")
    FileUtils.mkdir_p(output_dir)

    view_paths = ActionController::Base.view_paths.map(&:to_path)
    builder = ActionController::OpenApi::DocumentBuilder.new(
      view_paths: view_paths,
      info: ActionController::OpenApi.configuration.info
    )

    doc = builder.as_json
    json_string = JSON.pretty_generate(doc)

    json_path = output_dir.join("openapi.json")
    File.write(json_path, json_string)
    puts "Written: #{json_path}"

    redoc_js_source = ActionController::OpenApi.configuration.redoc_js_source
    redoc_script_tag =
      case redoc_js_source
      when :vendored
        redoc_js = File.read(
          File.expand_path(
            "../document_page/app/assets/javascripts/redoc.standalone.js",
            __dir__
          )
        )
        "<script>#{redoc_js}</script>"
      when :cdn
        "<script src=\"#{ActionController::OpenApi::CDN_REDOC_JS_URL}\"></script>"
      else
        "<script src=\"#{redoc_js_source}\"></script>"
      end

    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>API Documentation</title>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { margin: 0; padding: 0; }
        </style>
      </head>
      <body>
        <div id="redoc-container"></div>
        #{redoc_script_tag}
        <script>
          var spec = #{json_string};
          Redoc.init(spec, {}, document.getElementById('redoc-container'));
        </script>
      </body>
      </html>
    HTML

    html_path = output_dir.join("index.html")
    File.write(html_path, html)
    puts "Written: #{html_path}"
  end
end
