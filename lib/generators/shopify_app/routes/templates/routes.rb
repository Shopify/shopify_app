# frozen_string_literal: true

controller :sessions do
  get "login" => :new, :as => :login
  post "login" => :create, :as => :authenticate
  get "auth/shopify/callback" => :callback
  get "logout" => :destroy, :as => :logout
end

namespace :webhooks do
  post ":type" => :receive
end
