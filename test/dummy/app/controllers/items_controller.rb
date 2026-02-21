class ItemsController < ApplicationController
  ITEMS = [
    { id: 1, name: "Item 1" },
    { id: 2, name: "Item 2" },
    { id: 3, name: "Item 3" }
  ]

  around_action :validate_by_openapi_schema!

  def index
    render json: ITEMS
  end

  def show
    item = ITEMS.find { |i| i[:id] == params[:id].to_i }
    if item
      render json: item
    else
      render json: { error: "Not found" }, status: :not_found
    end
  end

  def create
    item = { id: ITEMS.length + 1, name: params[:name] }
    ITEMS << item
    render json: item, status: :created
  end
end
