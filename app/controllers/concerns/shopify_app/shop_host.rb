# frozen_string_literal: true

module ShopifyApp
  module ShopHost
    extend ActiveSupport::Concern

    SHOP_HOST_COOKIE = :shop_host

    included do
      before_action :set_shop_host
    end

    def set_shop_host
      @host = fetch_host_from_params
      @host ||= fetch_host_from_cookies
      save_shop_host(@host) if @host
      @host
    end

    private

    def fetch_host_from_params
      params[:host]
    end

    def fetch_host_from_cookies
      cookies[SHOP_HOST_COOKIE]
    end

    def save_shop_host(host)
      cookies[SHOP_HOST_COOKIE] = {
        value: host,
        expires: 1.day.from_now,
      }
    end
  end
end
