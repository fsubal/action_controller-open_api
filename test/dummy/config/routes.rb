Rails.application.routes.draw do
  resources :items, only: [:index, :show, :create]
  mount ActionController::OpenApi::DocumentPage::Engine, at: "/openapi"
end
