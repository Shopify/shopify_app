# frozen_string_literal: true

require "test_helper"
require "utils/rails_generator_runtime"
require "generators/shopify_app/home_controller/home_controller_generator"

module Utils
  class RailsGeneratorRuntimeTest < ActiveSupport::TestCase
    test "generates and clears classes" do
      runtime = Utils::RailsGeneratorRuntime.new(self)
      runtime.run_generator(ShopifyApp::Generators::HomeControllerGenerator)
      refute(defined?(HomeController))
      runtime.load_generated_classes("app/controllers/home_controller.rb")
      assert(defined?(HomeController))
      runtime.clear
      refute(defined?(HomeController))
    end
  end
end
