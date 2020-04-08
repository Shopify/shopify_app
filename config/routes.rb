# frozen_string_literal: true
ShopifyApp::Engine.routes.draw do
  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'enable_cookies' => :enable_cookies, :as => :enable_cookies
    get 'top_level_interaction' =>
      :top_level_interaction,
        :as => :top_level_interaction
    get 'granted_storage_access' =>
      :granted_storage_access,
        :as => :granted_storage_access
    get 'logout' => :destroy, :as => :logout
  end

  controller :callback do
    get 'auth/shopify/callback' => :callback
    get 'auth/shopify/jwt_callback' => :jwt_callback
  end

  namespace :webhooks do
    post ':type' => :receive
  end
end
