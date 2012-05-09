Rails.application.config.middleware.use OmniAuth::Builder do
  provider :shopify, 
           ShopifyApp.configuration.api_key, 
           ShopifyApp.configuration.secret,
           :scope => 'write_script_tags,write_shipping,write_orders,read_orders,read_products,read_customers,read_content',
           :setup => lambda {|env| 
                       params = Rack::Utils.parse_query(env['QUERY_STRING'])
                       site_url = "https://#{params['shop']}"
                       Rails.logger.info(env['omniauth.strategy'])
                       env['omniauth.strategy'].options[:client_options][:site] = site_url
                     }
end
