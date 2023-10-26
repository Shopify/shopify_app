# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class AddPrivacyJobsGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def add_customer_data_request_job
        template("customers_data_request_job.rb", "app/jobs/customers_data_request_job.rb")
      end

      def add_shop_redact_job
        template("shop_redact_job.rb", "app/jobs/shop_redact_job.rb")
      end

      def add_customer_redact_job
        template("customers_redact_job.rb", "app/jobs/customers_redact_job.rb")
      end
    end
  end
end
