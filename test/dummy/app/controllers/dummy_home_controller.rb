# frozen_string_literal: true

class DummyHomeController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled

  def index
    "index"
  end
end
