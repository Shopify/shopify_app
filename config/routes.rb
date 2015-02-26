if ShopifyApp.configuration.routes_enabled?
  Rails.application.routes.draw do
    controller :sessions do
      get 'login' => :new, :as => :login
      post 'login' => :create, :as => :authenticate
      get 'auth/shopify/callback' => :callback
      get 'logout' => :destroy, :as => :logout
    end
  end
end
