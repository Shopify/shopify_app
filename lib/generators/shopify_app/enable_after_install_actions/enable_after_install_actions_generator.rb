require 'rails/generators/base'

module ShopifyApp
  module Generators
    class EnableAfterInstallActionsGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      hook_for :test_framework, as: :job, in: :rails do |instance, generator|
        instance.invoke generator, [ instance.send(:job_file_name) ]
      end

      def init_after_install_config
        initializer = load_initializer
        return if initializer.include?("config.webhooks")

        inject_into_file(
          'config/initializers/shopify_app.rb',
          "  config.enable_after_install_actions = true\n",
          before: 'end'
        )
      end

      def add_after_install_job
        template 'after_install_job.rb', "app/jobs/#{job_file_name}_job.rb"
      end

      private

      def load_initializer
        File.read(File.join(destination_root, 'config/initializers/shopify_app.rb'))
      end

      def job_file_name
        'shopify/after_install'
      end
    end
  end
end
