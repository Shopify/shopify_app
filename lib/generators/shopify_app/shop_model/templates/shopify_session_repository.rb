if Rails.configuration.cache_classes
  ShopifyApp::SessionRepository.storage = SessionStorage
else
  ActionDispatch::Reloader.to_prepare do
    ShopifyApp::SessionRepository.storage = SessionStorage
  end
end
