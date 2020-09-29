# frozen_string_literal: true
class Session < ActiveRecord::Base
  include ShopifyApp::ActualSessionStorage

  def api_version
    ShopifyApp.configuration.api_version
  end
end
