# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class RotateShopifyTokenJobGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def add_rotate_shopify_token_job
        copy_file("rotate_shopify_token_job.rb", "app/jobs/shopify/rotate_shopify_token_job.rb")
        copy_file("rotate_shopify_token.rake", "lib/tasks/shopify/rotate_shopify_token.rake")
      end
    end
  end
end
