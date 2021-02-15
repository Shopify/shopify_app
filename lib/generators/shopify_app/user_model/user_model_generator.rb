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

      def create_scopes_storage_in_user_model
        scopes_column_prompt = <<~PROMPT
          It is highly recommended that apps record the access scopes granted by \
          merchants during app installation. See app/models/user.rb to modify how \
          access scopes are stored and retrieved.

          [WARNING] Your app will fail the ScopeVerification concern if access scopes are not stored.

          The following migration will add an `access_scopes` column to the User model. \
          Do you want to include this migration? [y/n]
        PROMPT

        if yes?(scopes_column_prompt)
          migration_template(
            'db/migrate/add_user_access_scopes_column.erb',
            'db/migrate/add_user_access_scopes_column.rb'
          )
        end
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
