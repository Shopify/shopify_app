# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class ShopModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      class_option :force_access_scopes_migration, type: :boolean, default: false

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

          [WARNING] You will need to update the access_scopes accessors in the Shop model \
          to allow shopify_app to store and retrieve scopes when going through OAuth.

          The following migration will add an `access_scopes` column to the Shop model. \
          Do you want to include this migration? [y/n]
        PROMPT

        if force_access_scopes_migration? || Rails.env.test? || yes?(scopes_column_prompt)
          migration_template(
            'db/migrate/add_shop_access_scopes_column.erb',
            'db/migrate/add_shop_access_scopes_column.rb'
          )
        end
      end

      def update_shopify_app_initializer
        gsub_file('config/initializers/shopify_app.rb', 'ShopifyApp::InMemoryShopSessionStore', 'Shop')
      end

      def create_shop_fixtures
        copy_file('shops.yml', 'test/fixtures/shops.yml')
      end

      private

      def force_access_scopes_migration?
        options['force_access_scopes_migration']
      end

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
