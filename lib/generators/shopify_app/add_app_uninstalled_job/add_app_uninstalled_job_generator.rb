# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class AddAppUninstalledJobGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_job
        template("app_uninstalled_job.rb", "app/jobs/app_uninstalled_job.rb")
      end
    end
  end
end
