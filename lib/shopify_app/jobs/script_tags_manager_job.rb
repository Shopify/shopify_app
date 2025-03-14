# frozen_string_literal: true

module ShopifyApp
  class ScriptTagsManagerJob < ActiveJob::Base
    queue_as do
      ShopifyApp.configuration.script_tags_manager_queue_name
    end

    def perform(shop_domain:, shop_token:, script_tags:)
      ShopifyAPI::Auth::Session.temp(shop: shop_domain, access_token: shop_token) do |session|
        manager = ScriptTagsManager.new(script_tags, shop_domain)
        manager.create_script_tags(session: session)
      end
    end
  end
end
