# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class ShopModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_shop_model
        copy_file('shop.rb', 'app/models/shop.rb')
      end

      def create_shop_migration
        migration_template('db/migrate/create_shops.erb', 'db/migrate/create_shops.rb')
      end

      def create_shop_with_access_scopes_migration
        scopes_column_prompt = <<~PROMPT
          It is highly recommended that apps record the access scopes granted by \
          merchants during app installation. See app/models/shop.rb to modify how \
          access scopes are stored and retrieved.

          [WARNING] Your app will fail the ScopeVerification concern if access scopes are not stored.

          The following migration will add an `access_scopes` column to the Shop model. \
          Do you want to include this migration? [y/n]
        PROMPT

        if yes?(scopes_column_prompt)
          migration_template('db/migrate/add_scopes_column.erb', 'db/migrate/add_scopes_column.rb')
        end
      end

      def update_shopify_app_initializer
        gsub_file('config/initializers/shopify_app.rb', 'ShopifyApp::InMemoryShopSessionStore', 'Shop')
      end

      def create_shop_fixtures
        copy_file('shops.yml', 'test/fixtures/shops.yml')
      end

      private

      def rails_migration_version
        Rails.version.match(/\d\.\d/)[0]
      end

      class << self
        private :next_migration_number

        # for generating a timestamp when using `create_migration`
        def next_migration_number(dir)
          ActiveRecord::Generators::Base.next_migration_number(dir)
        end
      end
    end
  end
end
