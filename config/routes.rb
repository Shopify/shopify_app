# frozen_string_literal: true
ShopifyApp::Engine.routes.draw do
  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'logout' => :destroy, :as => :logout
  end

  controller :callback do
    get 'auth/shopify/callback' => :callback
  end

  namespace :webhooks do
    post ':type' => :receive
  end
end
