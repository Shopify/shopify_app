  provider :shopify,
    ShopifyApp.configuration.api_key,
    ShopifyApp.configuration.secret,

    :scope => ShopifyApp.configuration.scope,

    :setup => lambda {|env|
       params = Rack::Utils.parse_query(env['QUERY_STRING'])
       site_url = "https://#{params['shop']}"
       env['omniauth.strategy'].options[:client_options][:site] = site_url
    }
