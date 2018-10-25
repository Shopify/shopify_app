# frozen_string_literal: true

module ShopifyApp
  # Cookie management helpers required for ITP implementation
  module Itp
    private

    def set_test_cookie
      return unless ShopifyApp.configuration.embedded_app?
      return unless user_agent_can_partition_cookies

      session['shopify.cookies_persist'] = true
    end

    def set_top_level_oauth_cookie
      session['shopify.top_level_oauth'] = true
    end

    def clear_top_level_oauth_cookie
      session.delete('shopify.top_level_oauth')
    end

    def user_agent_is_mobile
      mobile_regex = %r{Shopify Mobile/iOS}
      request.user_agent.match(mobile_regex)
    end

    def user_agent_is_pos
      point_of_sale_regex = %r{com.jadedpixel.pos}
      request.user_agent.match(point_of_sale_regex)
    end

    def user_agent_can_partition_cookies
      regex = %r{Version\/12\.0\.?\d? Safari}
      request.user_agent.match(regex)
    end
  end
end
