# frozen_string_literal: true
module ShopifyApp
  class AuthenticatedController < ActionController::Base
    include ShopifyApp::Authenticated

    protect_from_forgery with: :exception
  end
end
