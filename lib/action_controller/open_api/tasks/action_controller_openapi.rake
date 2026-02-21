namespace :action_controller_openapi do
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
        <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
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
