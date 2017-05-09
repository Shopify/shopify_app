module ShopifyApp
  module Shop
    extend ActiveSupport::Concern

    included do
      validates :shopify_domain, presence: true, uniqueness: { scope: :associated_user_id }
      validates :shopify_token, presence: true
    end

    def with_shopify_session(&block)
      ShopifyAPI::Session.temp(shopify_domain, shopify_token, extra, &block)
    end

    def extra
      @extra ||= JSON.parse(extra_json, object_class: OpenStruct) if extra_json
    end

    def associated_scope
      extra.try(:associated_user_scope)
    end

    def associated_user
      extra.try(:associated_user)
    end

    def app_scope
      extra.try(:scope)
    end

    def authorized_scope
      associated_scope || app_scope
    end

  end
end
