require 'shopify_app/version'

# deps
require 'shopify_api'
require 'omniauth-shopify-oauth2'

module ShopifyApp
  def self.rails6?
    Rails::VERSION::MAJOR >= 6
  end

  def self.use_webpacker?
    rails6? &&
      defined?(Webpacker) == 'constant' &&
      !configuration.disable_webpacker
  end

  # config
  require 'shopify_app/configuration'

  # engine
  require 'shopify_app/engine'

  # utils
  require 'shopify_app/utils'

  # controllers
  require 'shopify_app/controllers/extension_verification_controller'

  # controller concerns
  require 'shopify_app/controller_concerns/localization'
  require 'shopify_app/controller_concerns/itp'
  require 'shopify_app/controller_concerns/login_protection'
  require 'shopify_app/controller_concerns/embedded_app'
  require 'shopify_app/controller_concerns/webhook_verification'
  require 'shopify_app/controller_concerns/app_proxy_verification'

  # jobs
  require 'shopify_app/jobs/webhooks_manager_job'
  require 'shopify_app/jobs/scripttags_manager_job'

  # managers
  require 'shopify_app/managers/webhooks_manager'
  require 'shopify_app/managers/scripttags_manager'

  # session
  require 'shopify_app/session/session_storage'
  require 'shopify_app/session/session_repository'
  require 'shopify_app/session/in_memory_session_store'
end
