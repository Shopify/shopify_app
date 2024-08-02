# frozen_string_literal: true

Rails.application.routes.draw do
  scope path: :api, format: :json do
    # POST /api/products and GET /api/products/count
    resources :products, only: :create do
      collection do
        get :count
      end
    end
    namespace :webhooks do
      post "/app_uninstalled", to: "app_uninstalled#receive"
      post "/customers_data_request", to: "customers_data_request#receive"
      post "/customers_redact", to: "customers_redact#receive"
      post "/shop_redact", to: "shop_redact#receive"
    end
  end

  mount ShopifyApp::Engine, at: "/"
  root to: "application#show"
end
