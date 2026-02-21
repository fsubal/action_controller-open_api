ActionController::OpenApi::DocumentPage::Engine.routes.draw do
  root to: "documents#show"
  get "openapi.json", to: "documents#schema", as: :schema
  get "redoc.standalone.js", to: "documents#redoc_js", as: :redoc_js
end
