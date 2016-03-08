Rails.application.routes.draw do
  mount ShopifyApp::Engine, at: '/'
  root to: 'home#index'
end
