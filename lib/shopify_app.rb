# frozen_string_literal: true

require "shopify_app/version"

# deps
require "redirect_safely"
require "addressable"
require "shopify_app_ai"

module ShopifyApp
  def self.rails6?
    Rails::VERSION::MAJOR >= 6
  end

  def self.rails7?
    Rails::VERSION::MAJOR >= 7
  end

  def self.use_importmap?
    rails7? && File.exist?("config/importmap.rb")
  end

  def self.use_webpacker?
    rails6? &&
      defined?(Webpacker) == "constant" &&
      !configuration.disable_webpacker
  end

  # config
  require "shopify_app/configuration"

  # engine
  require "shopify_app/engine"

  # utils
  require "shopify_app/utils"

  # errors
  require "shopify_app/errors"

  require "shopify_app/logger"

  # Auth models (must be loaded before session modules)
  require "shopify_app/auth/auth_scopes"
  require "shopify_app/auth/associated_user"
  require "shopify_app/auth/session"

  # Session management
  require "shopify_app/session_context"
  require "shopify_app/session_utils"

  # Admin API helpers
  require "shopify_app/admin_api/with_token_refetch"

  # controller concerns
  require "shopify_app/controller_concerns/csrf_protection"
  require "shopify_app/controller_concerns/localization"
  require "shopify_app/controller_concerns/frame_ancestors"
  require "shopify_app/controller_concerns/sanitized_params"
  require "shopify_app/controller_concerns/redirect_for_embedded"
  require "shopify_app/controller_concerns/login_protection"
  require "shopify_app/controller_concerns/ensure_billing"
  require "shopify_app/controller_concerns/embedded_app"
  require "shopify_app/controller_concerns/payload_verification"
  require "shopify_app/controller_concerns/app_proxy_verification"
  require "shopify_app/controller_concerns/webhook_verification"
  require "shopify_app/controller_concerns/token_exchange"
  require "shopify_app/controller_concerns/with_shopify_id_token"

  # Auth helpers
  require "shopify_app/auth/post_authenticate_tasks"
  require "shopify_app/auth/token_exchange"

  # jobs
  require "shopify_app/jobs/webhooks_manager_job"
  require "shopify_app/jobs/script_tags_manager_job"

  # managers
  require "shopify_app/managers/webhooks_manager"
  require "shopify_app/managers/script_tags_manager"

  # session
  require "shopify_app/session/in_memory_session_store"
  require "shopify_app/session/in_memory_shop_session_store"
  require "shopify_app/session/in_memory_user_session_store"
  require "shopify_app/session/null_user_session_store"
  require "shopify_app/session/session_repository"
  require "shopify_app/session/session_storage"
  require "shopify_app/session/shop_session_storage"
  require "shopify_app/session/shop_session_storage_with_scopes"
  require "shopify_app/session/user_session_storage"
  require "shopify_app/session/user_session_storage_with_scopes"

  # access scopes strategies
  require "shopify_app/access_scopes/shop_strategy"
  require "shopify_app/access_scopes/user_strategy"
  require "shopify_app/access_scopes/noop_strategy"
end
