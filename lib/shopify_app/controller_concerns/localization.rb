# frozen_string_literal: true

module ShopifyApp
  module Localization
    extend ActiveSupport::Concern

    included do
      before_action :set_locale
    end

    private

    def set_locale
      if params[:locale]
        session[:locale] = params[:locale]
      else
        session[:locale] ||= I18n.default_locale
      end
      I18n.locale = session[:locale]
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
  end
end
