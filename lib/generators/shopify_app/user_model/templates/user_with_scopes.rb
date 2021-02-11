# frozen_string_literal: true
class User < ActiveRecord::Base
  include ShopifyApp::UserSessionStorage

  def access_scopes=(scopes)
    super(scopes)
  end

  def access_scopes
    super
  end

  def api_version
    ShopifyApp.configuration.api_version
  end
end
