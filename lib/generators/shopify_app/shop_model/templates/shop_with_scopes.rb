# frozen_string_literal: true
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage

  def self.update_scopes(shop, scopes)
    shop.scopes = scopes
  end

  def api_version
    ShopifyApp.configuration.api_version
  end
end
