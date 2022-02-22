# frozen_string_literal: true

require "test_helper"
require "utils/generated_sources"
require "generators/shopify_app/home_controller/home_controller_generator"

module Utils
  class GeneratedSourcesTest < ActiveSupport::TestCase
    test "generates and clears classes" do
      sources = Utils::GeneratedSources.new(self)
      sources.run_generator(ShopifyApp::Generators::HomeControllerGenerator)
      refute(defined?(HomeController))
      sources.load_generated_classes("app/controllers/home_controller.rb")
      assert(defined?(HomeController))
      sources.clear
      refute(defined?(HomeController))
    end
  end
end
