# frozen_string_literal: true
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage

  def scopes=(scopes)
    super(scopes)
  end

  def scopes
    super
  end

  def api_version
    ShopifyApp.configuration.api_version
  end
end
