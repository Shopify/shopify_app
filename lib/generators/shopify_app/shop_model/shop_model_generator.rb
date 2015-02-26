require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class ShopModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_or_inject_into_shop_model
        if File.exist? "app/models/shop.rb"
          inject_into_file(
            "app/models/shop.rb",
            "include ShopifyApp::Shop\n\n",
            after: "class Shop < ActiveRecord::Base\n"
          )
        else
          copy_file 'shop.rb', 'app/models/shop.rb'
        end
      end

      def create_shop_migration
        if shops_table_exists?
          create_add_columns_migration
        else
          copy_migration 'create_shops.rb'
        end
      end

      def create_session_storage
        copy_file 'session_store.rb', 'app/models/session_storage.rb'
      end

      def create_session_storage_initializer
        copy_file 'shopify_session_repository.rb', 'config/initializers/shopify_session_repository.rb'
      end

      private

      def create_add_columns_migration
        if migration_needed?
          config = {
            new_columns: new_columns,
            new_indexes: new_indexes
          }

          copy_migration('add_to_shops.rb', config)
        end
      end

      def copy_migration(migration_name, config = {})
        unless migration_exists?(migration_name)
          migration_template(
            "db/migrate/#{migration_name}",
            "db/migrate/#{migration_name}",
            config
          )
        end
      end

      def migration_needed?
        new_columns.any? || new_indexes.any?
      end

      def new_columns
        @new_columns ||= {
          shopify_domain: 't.string :shopify_domain',
          shopify_token: 't.string :shopify_token'
        }.reject { |column| existing_shops_columns.include?(column.to_s) }
      end

      def new_indexes
        @new_indexes ||= {
          index_shops_on_shopify_domain: 'add_index :shops, :shopify_domain',
        }.reject { |index| existing_shops_indexes.include?(index.to_s) }
      end

      def migration_exists?(name)
        existing_migrations.include?(name)
      end

      def existing_migrations
        @existing_migrations ||= Dir.glob("db/migrate/*.rb").map do |file|
          migration_name_without_timestamp(file)
        end
      end

      def migration_name_without_timestamp(file)
        file.sub(%r{^.*(db/migrate/)(?:\d+_)?}, '')
      end

      def shops_table_exists?
        ActiveRecord::Base.connection.table_exists?(:shops)
      end

      def existing_shops_columns
        ActiveRecord::Base.connection.columns(:shops).map(&:name)
      end

      def existing_shops_indexes
        ActiveRecord::Base.connection.indexes(:shops).map(&:name)
      end

      # for generating a timestamp when using `create_migration`
      def self.next_migration_number(dir)
        ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
