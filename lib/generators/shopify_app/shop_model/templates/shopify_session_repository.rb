if Rails.configuration.cache_classes
  ShopifyApp::SessionRepository.storage = Shop
else
  reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader

  reloader.to_prepare do
    ShopifyApp::SessionRepository.storage = Shop
  end
end
