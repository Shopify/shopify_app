module ShopifyApp
  class ScripttagsManager
    class CreationFailed < StandardError; end

    def self.queue(shop_name, token)
      ShopifyApp::ScripttagsManagerJob.perform_later(shop_name: shop_name, token: token)
    end

    def initialize(shop_name, token)
      @shop_name, @token = shop_name, token
    end

    def recreate_scripttags!
      destroy_scripttags
      create_scripttags
    end

    def create_scripttags
      return unless required_scripttags.present?

      with_shopify_session do
        required_scripttags.each do |scripttag|
          create_scripttag(scripttag) unless scripttag_exists?(scripttag[:src])
        end
      end
    end

    def destroy_scripttags
      with_shopify_session do
        ShopifyAPI::ScriptTag.all.each do |scripttag|
          ShopifyAPI::ScriptTag.delete(scripttag.id) if is_required_scripttag?(scripttag)
        end
      end
      @current_scripttags = nil
    end

    private

    def required_scripttags
      ShopifyApp.configuration.scripttags
    end

    def is_required_scripttag?(scripttag)
      required_scripttags.map{ |w| w[:src] }.include? scripttag.src
    end

    def with_shopify_session
      ShopifyAPI::Session.temp(@shop_name, @token) do
        yield
      end
    end

    def create_scripttag(attributes)
      attributes.reverse_merge!(format: 'json')
      scripttag = ShopifyAPI::ScriptTag.create(attributes)
      raise CreationFailed unless scripttag.persisted?
      scripttag
    end

    def scripttag_exists?(src)
      current_scripttags[src]
    end

    def current_scripttags
      @current_scripttags ||= ShopifyAPI::ScriptTag.all.index_by(&:src)
    end
  end
end
