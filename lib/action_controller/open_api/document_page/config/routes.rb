ActionController::OpenApi::DocumentPage::Engine.routes.draw do
  root to: "documents#show"
  get "openapi.json", to: "documents#schema", as: :schema
end
