# frozen_string_literal: true

module ShopifyApp
  module Generators
    class ShopifyAppGenerator < Rails::Generators::Base
      def initialize(args, *options)
        @opts = options.first
        super(args, *options)
      end

      def run_all_generators
        generate("shopify_app:install #{@opts.join(" ")}")
        generate("shopify_app:shop_model #{@opts.join(" ")}")
        generate("shopify_app:authenticated_controller")
        generate("shopify_app:home_controller #{@opts.join(" ")}")
        generate("shopify_app:add_app_uninstall_job")
      end
    end
  end
end
