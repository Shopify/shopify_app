# frozen_string_literal: true

class ExtensionVerificationController < ActionController::Base
  before_action :verify_request

  private

  def verify_request
    hmac_header = request.headers['HTTP_X_SHOPIFY_HMAC_SHA256']
    request_body = request.body.read
    secret = ShopifyApp.configuration.secret
    digest = OpenSSL::Digest.new('sha256')

    expected_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, request_body))
    head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(expected_hmac, hmac_header)
  end
end
