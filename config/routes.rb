# frozen_string_literal: true

ShopifyApp::Engine.routes.draw do
  login_url = ShopifyApp.configuration.login_url.gsub(/^#{ShopifyApp.configuration.root_url}/, "")
  login_callback_url = ShopifyApp.configuration.login_callback_url.gsub(/^#{ShopifyApp.configuration.root_url}/, "")

  controller :sessions do
    get login_url => :new, :as => :login
    post login_url => :create, :as => :authenticate
    get "logout" => :destroy, :as => :logout
  end

  controller :callback do
    get login_callback_url => :callback
  end

  namespace :webhooks do
    post ":type" => :receive
  end
end
