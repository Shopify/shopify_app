# frozen_string_literal: true

module ShopifyApp
  class ExtensionVerificationController < ActionController::Base
    include ShopifyApp::PayloadVerification
    protect_from_forgery with: :null_session
    before_action :verify_request
  end
end
