require 'shopify_api'
require 'shopify_login_protection'

begin
  ShopifyAPI::Session.setup(YAML.load(ERB.new(File.read("#{RAILS_ROOT}/config/shopify.yml")).result)[RAILS_ENV])

  ActionController::Base.send :include, ShopifyLoginProtection
  ActionController::Base.send :helper_method, :current_shop
rescue Errno::ENOENT
  STDERR.puts '** [!] Shopify app plugin installed but no config/shopify.yml found.'
end