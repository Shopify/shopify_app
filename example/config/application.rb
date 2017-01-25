require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Example
  class Application < Rails::Application
    config.action_dispatch.default_headers['P3P'] = 'CP="Not used"'
    config.action_dispatch.default_headers.delete('X-Frame-Options')
    config.active_record.raise_in_transactional_callbacks = true

    Rails.application.routes.default_url_options[:protocol] = ENV['DEFAULT_PROTOCOL'] if ENV['PROTOCOL']
    Rails.application.routes.default_url_options[:host] = ENV['DEFAULT_HOST'] if ENV['HOST']

    config.after_initialize do
      ShopifyAPI::Session.myshopify_domain = ShopifyApp.configuration.myshopify_domain
    end
  end
end
