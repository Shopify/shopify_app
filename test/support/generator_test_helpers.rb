# frozen_string_literal: true

module GeneratorTestHelpers
  TEMPLATE_PATH = File.expand_path("../../app_templates", __FILE__)

  def provide_existing_gemfile
    copy_to_generator_root("", "Gemfile")
  end

  def provide_existing_application_controller
    copy_to_generator_root("app/controllers", "application_controller.rb")
  end

  def provide_existing_application_file
    copy_to_generator_root("config", "application.rb")
  end

  def provide_existing_routes_file
    copy_to_generator_root("config", "routes.rb")
  end

  def provide_existing_initializer_file
    copy_to_generator_root("config/initializers", "shopify_app.rb")
  end

  def provide_existing_initializer_file_with_webhooks
    copy_to_generator_root("config/initializers", "shopify_app_with_webhooks.rb", rename: "shopify_app.rb")
  end

  def provide_development_config_file
    copy_to_generator_root("config/environments", "development.rb")
  end

  private

  def copy_to_generator_root(destination, template, rename: nil)
    template_file = File.join(TEMPLATE_PATH, destination, template)
    destination = File.join(destination_root, destination)

    FileUtils.mkdir_p(destination)
    FileUtils.cp(template_file, destination)

    if rename
      FileUtils.mv(
        File.join(destination, template),
        File.join(destination, rename),
      )
    end
  end
end
