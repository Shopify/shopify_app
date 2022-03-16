# frozen_string_literal: true

module ShopifyApp
  # Cookie management helpers required for ITP implementation
  module Itp
    private

    def set_test_cookie
      return unless ShopifyApp.configuration.embedded_app?
      return unless user_agent_can_partition_cookies

      session["shopify.cookies_persist"] = true
    end

    def set_top_level_oauth_cookie
      session["shopify.top_level_oauth"] = true
    end

    def clear_top_level_oauth_cookie
      session.delete("shopify.top_level_oauth")
    end

    def user_agent_is_mobile
      user_agent = BrowserSniffer.new(request.user_agent).browser_info

      user_agent[:name].to_s.match(/Shopify\sMobile/)
    end

    def user_agent_is_pos
      user_agent = BrowserSniffer.new(request.user_agent).browser_info

      user_agent[:name].to_s.match(/Shopify\sPOS/)
    end

    def user_agent_can_partition_cookies
      user_agent = BrowserSniffer.new(request.user_agent).browser_info

      is_safari = user_agent[:name].to_s.match(/Safari/)

      return false unless is_safari

      user_agent[:version].to_s.match(/12\.0/)
    end
  end
end
