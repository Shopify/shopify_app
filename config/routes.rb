# frozen_string_literal: true

ShopifyApp::Engine.routes.draw do
  login_url = ShopifyApp.configuration.login_url.gsub(/^#{ShopifyApp.configuration.root_url}/, "")
  login_callback_url = ShopifyApp.configuration.login_callback_url.gsub(/^#{ShopifyApp.configuration.root_url}/, "")

  controller :sessions do
    get login_url => :new, :as => :login
    post login_url => :create, :as => :authenticate
    get "logout" => :destroy, :as => :logout

    if ShopifyApp.configuration.embedded_redirect_url.present?
      embedded_redirect_url = ShopifyApp.configuration.embedded_redirect_url.gsub(/^#{ShopifyApp.configuration.root_url}/, "")
      get embedded_redirect_url => :exitiframe, :as => :exitiframe
    end

    # Kept to prevent apps relying on these routes from breaking
    if login_url.gsub(%r{^/}, "") != "login"
      get "login" => :new, :as => :default_login
      post "login" => :create, :as => :default_authenticate
    end
  end

  controller :callback do
    get login_callback_url => :callback

    # Kept to prevent apps relying on these routes from breaking
    if login_callback_url.gsub(%r{^/}, "") != "auth/shopify/callback"
      get "auth/shopify/callback" => :default_callback
    end
  end

  namespace :webhooks do
    post ":type" => :receive
  end
end
