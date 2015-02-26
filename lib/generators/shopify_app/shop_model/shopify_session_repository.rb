if Rails.configuration.cache_classes
  ShopifySessionRepository.storage = SessionStorage
else
  ActionDispatch::Reloader.to_prepare do
    ShopifySessionRepository.storage = SessionStorage
  end
end
