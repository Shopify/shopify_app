# frozen_string_literal: true

Rails.application.routes.draw do
  root :to => 'dummy_home#index'
  namespace :webhooks do
    # Add your webhook routes here
  end
  mount ShopifyApp::Engine, at: '/'
end
