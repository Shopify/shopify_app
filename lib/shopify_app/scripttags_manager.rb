module ShopifyApp
  class ScripttagsManager
    class CreationFailed < StandardError; end

    def self.queue(shop_domain, shop_token, scripttags)
      ShopifyApp::ScripttagsManagerJob.perform_later(
        shop_domain: shop_domain,
        shop_token: shop_token,
        scripttags: scripttags
      )
    end

    attr_reader :required_scripttags

    def initialize(scripttags)
      @required_scripttags = scripttags
    end

    def recreate_scripttags!
      destroy_scripttags
      create_scripttags
    end

    def create_scripttags
      return unless required_scripttags.present?

      required_scripttags.each do |scripttag|
        create_scripttag(scripttag) unless scripttag_exists?(scripttag[:src])
      end
    end

    def destroy_scripttags
      ShopifyAPI::ScriptTag.all.each do |scripttag|
        ShopifyAPI::ScriptTag.delete(scripttag.id) if is_required_scripttag?(scripttag)
      end

      @current_scripttags = nil
    end

    private

    def is_required_scripttag?(scripttag)
      required_scripttags.map{ |w| w[:src] }.include? scripttag.src
    end

    def create_scripttag(attributes)
      attributes.reverse_merge!(format: 'json')
      scripttag = ShopifyAPI::ScriptTag.create(attributes)
      raise CreationFailed, scripttag.errors.full_messages.to_sentence unless scripttag.persisted?
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
