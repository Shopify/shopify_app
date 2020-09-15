# frozen_string_literal: true
require 'rails/generators/base'
require 'rails/generators/active_record'

module ShopifyApp
  module Generators
    class SessionModelGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      def create_session_model
        copy_file('session.rb', 'app/models/session.rb')
      end

      def create_session_migration
        migration_template('db/migrate/create_sessions.erb', 'db/migrate/create_sessions.rb')
      end

      def update_shopify_app_initializer
        gsub_file('config/initializers/shopify_app.rb', 'ShopifyApp::InMemoryActualSessionStore', 'Session')
      end

      def create_session_fixtures
        copy_file('sessions.yml', 'test/fixtures/sessions.yml')
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
