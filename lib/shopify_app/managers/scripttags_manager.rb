# frozen_string_literal: true
module ShopifyApp
  class ScripttagsManager
    class CreationFailed < StandardError; end

    def self.queue(shop_domain, shop_token, scripttags)
      ShopifyApp::ScripttagsManagerJob.perform_later(
        shop_domain: shop_domain,
        shop_token: shop_token,
        # Procs cannot be serialized so we interpolate now, if necessary
        scripttags: build_src(scripttags, shop_domain)
      )
    end

    def self.build_src(scripttags, domain)
      scripttags.map do |tag|
        next tag unless tag[:src].respond_to?(:call)
        tag = tag.dup
        tag[:src] = tag[:src].call(domain)
        tag
      end
    end

    attr_reader :required_scripttags, :shop_domain

    def initialize(scripttags, shop_domain)
      @required_scripttags = scripttags
      @shop_domain = shop_domain
    end

    def recreate_scripttags!
      destroy_scripttags
      create_scripttags
    end

    def create_scripttags
      return unless required_scripttags.present?

      expanded_scripttags.each do |scripttag|
        create_scripttag(scripttag) unless scripttag_exists?(scripttag[:src])
      end
    end

    def destroy_scripttags
      scripttags = expanded_scripttags
      ShopifyAPI::ScriptTag.all(session: ShopifyAPI::Context.active_session).each do |tag|
        tag.delete if required_scripttag?(scripttags, tag)
      end

      @current_scripttags = nil
    end

    private

    def expanded_scripttags
      self.class.build_src(required_scripttags, shop_domain)
    end

    def required_scripttag?(scripttags, tag)
      scripttags.map { |w| w[:src] }.include?(tag.src)
    end

    def create_scripttag(attributes)
      scripttag = ShopifyAPI::ScriptTag.new(session: ShopifyAPI::Context.active_session)
      attributes.each { |key, value| scripttag.public_send("#{key.to_s}=", value) }

      begin
        scripttag.save!
      rescue ShopifyAPI::Errors::HttpResponseError => e
        raise CreationFailed, e.message
      end

      scripttag
    end

    def scripttag_exists?(src)
      current_scripttags[src]
    end

    def current_scripttags
      @current_scripttags ||= ShopifyAPI::ScriptTag.all(session: ShopifyAPI::Context.active_session).index_by(&:src)
    end
  end
end
