# frozen_string_literal: true

module ShopifyApp
  module SetShopHost
    extend ActiveSupport::Concern

    included do
      before_action :set_shop_host
    end

    private

    def set_shop_host
      @host = params[:host] ||= request.headers["shopify-app-bridge-host"]
    end
  end
end
