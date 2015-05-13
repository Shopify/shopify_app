module ShopifyApp
  module Generators
    class ShopifyAppGenerator < Rails::Generators::Base

      def initialize(args, *options)
        @opts = options.first
        super(args, *options)
      end

      def run_all_generators
        generate "shopify_app:install #{@opts.join(' ')}"
        generate "shopify_app:shop_model"

        generate "shopify_app:controllers"
        generate "shopify_app:views"
        generate "shopify_app:routes"
      end

    end
  end
end
