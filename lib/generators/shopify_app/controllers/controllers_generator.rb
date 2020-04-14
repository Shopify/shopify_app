# frozen_string_literal: true
require 'rails/generators/base'

module ShopifyApp
  module Generators
    class ControllersGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../..", __FILE__)

      def create_controllers
        controllers.each do |controller|
          copy_file controller
        end
      end

      private

      def controllers
        files_within_root('.', 'app/controllers/shopify_app/*.*')
      end

      def files_within_root(prefix, glob)
        root = "#{self.class.source_root}/#{prefix}"

        Dir["#{root}/#{glob}"].sort.map do |full_path|
          full_path.sub(root, '.').gsub('/./', '/')
        end
      end
    end
  end
end
