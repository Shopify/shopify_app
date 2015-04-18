class ActiveSupport::TestCase
  TEMPLATE_PATH = File.expand_path("../../app_templates", __FILE__)

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

  private

  def copy_to_generator_root(destination, template)
    template_file = File.join(TEMPLATE_PATH, destination, template)
    destination = File.join(destination_root, destination)

    FileUtils.mkdir_p(destination)
    FileUtils.cp(template_file, destination)
  end
end
