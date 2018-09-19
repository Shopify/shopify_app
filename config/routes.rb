ShopifyApp::Engine.routes.draw do
  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'enable_cookies' => :enable_cookies, :as => :enable_cookies
    get 'request_storage_access' => :request_storage_access, :as => :request_storage_access
    get 'auth/shopify/callback' => :callback
    get 'logout' => :destroy, :as => :logout
  end

  namespace :webhooks do
    post ':type' => :receive
  end
end
