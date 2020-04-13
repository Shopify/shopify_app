# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class UserModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_user_model
        copy_file('user.rb', 'app/models/user.rb')
      end

      def create_user_migration
        migration_template('db/migrate/create_users.erb', 'db/migrate/create_users.rb')
      end

      def update_shopify_app_initializer
        gsub_file('config/initializers/shopify_app.rb', 'ShopifyApp::InMemoryUserSessionStore', 'User')
      end

      def create_user_fixtures
        copy_file('users.yml', 'test/fixtures/users.yml')
      end

      private

      def rails_migration_version
        Rails.version.match(/\d\.\d/)[0]
      end

      # for generating a timestamp when using `create_migration`
      def self.next_migration_number(dir)
        ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
