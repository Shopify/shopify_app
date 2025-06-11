# frozen_string_literal: true

module ShopifyApp
  class ScriptTagsManagerJob < ActiveJob::Base
    queue_as { ShopifyApp.configuration.script_tags_manager_queue_name }

    def perform(shop_domain:, shop_token:, script_tags:)
      ShopifyApp::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do |session|
        ShopifyApp::ScriptTagsManager.new(script_tags: script_tags, session: session).recreate_script_tags!
      end
    end
  end
end
