# frozen_string_literal: true

module ShopifyApp
  module Localization
    extend ActiveSupport::Concern

    included do
      before_action :set_locale
    end

    private

    def set_locale
      locale = params[:locale] || I18n.default_locale

      # Fallback to the 2 letter language code if the requested locale unavailable
      unless I18n.available_locales.include?(locale.to_sym)
        locale = locale.split("-").first
      end

      session[:locale] = locale
      I18n.locale = session[:locale]
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
  end
end
