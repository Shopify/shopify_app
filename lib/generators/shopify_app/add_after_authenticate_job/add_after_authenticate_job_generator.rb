require 'rails/generators/base'

module ShopifyApp
  module Generators
    class AddAfterAuthenticateJobGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      hook_for :test_framework, as: :job, in: :rails do |instance, generator|
        instance.invoke generator, [ instance.send(:job_file_name) ]
      end

      def init_after_authenticate_config
        initializer = load_initializer

       after_authenticate_job_config = "  config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: false }\n"

        inject_into_file(
          'config/initializers/shopify_app.rb',
          after_authenticate_job_config,
          before: 'end'
        )

        unless initializer.include?(after_authenticate_job_config)
          shell.say "Error adding after_authenticate_job to config. Add this line manually: #{after_authenticate_job_config}", :red
        end
      end

      def add_after_authenticate_job
        template 'after_authenticate_job.rb', "app/jobs/#{job_file_name}_job.rb"
      end

      private

      def load_initializer
        File.read(File.join(destination_root, 'config/initializers/shopify_app.rb'))
      end

      def job_file_name
        'shopify/after_authenticate'
      end
    end
  end
end
