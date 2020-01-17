module ShopifyApp
  class SameSiteCookieMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      _status, headers, _body = @app.call(env)
    ensure
      user_agent = env['HTTP_USER_AGENT']

      if headers && headers['Set-Cookie'] && !SameSiteCookieMiddleware.same_site_none_incompatible?(user_agent) &&
          ShopifyApp.configuration.enable_same_site_none

        cookies = headers['Set-Cookie'].split("\n").compact

        cookies.each do |cookie|
          unless cookie.include?("; SameSite")
            headers['Set-Cookie'] = headers['Set-Cookie'].gsub("#{cookie}", "#{cookie}; secure; SameSite=None\n")
          end
        end
      end
    end

    def self.same_site_none_incompatible?(user_agent)
      sniffer = BrowserSniffer.new(user_agent)

      webkit_same_site_bug?(sniffer) || drops_unrecognized_same_site_cookies?(sniffer)
    rescue
      true
    end

    def self.webkit_same_site_bug?(sniffer)
      (sniffer.os == :ios && sniffer.os_version.match?(/^([0-9]|1[12])[\.\_]/)) ||
        (sniffer.os == :mac && sniffer.browser == :safari && sniffer.os_version.match?(/^10[\.\_]14/))
    end

    def self.drops_unrecognized_same_site_cookies?(sniffer)
      (chromium_based?(sniffer) && sniffer.major_browser_version >= 51 && sniffer.major_browser_version <= 66) ||
        (uc_browser?(sniffer) && !uc_browser_version_at_least?(sniffer: sniffer, major: 12, minor: 13, build: 2))
    end

    def self.chromium_based?(sniffer)
      sniffer.browser_name.downcase.match?(/chrom(e|ium)/)
    end

    def self.uc_browser?(sniffer)
      sniffer.user_agent.downcase.match?(/uc\s?browser/)
    end

    def self.uc_browser_version_at_least?(sniffer:, major:, minor:, build:)
      digits = sniffer.browser_version.split('.').map(&:to_i)
      return false unless digits.count >= 3

      return digits[0] > major if digits[0] != major
      return digits[1] > minor if digits[1] != minor
      digits[2] >= build
    end
  end
end
