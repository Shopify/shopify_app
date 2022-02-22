# frozen_string_literal: true

require "test_helper"
require "utils/rails_generator_runtime"
require "generators/shopify_app/home_controller/home_controller_generator"

module Utils
  class RailsGeneratorRuntimeTest < ActiveSupport::TestCase
    test "generates and clears classes" do
      runtime = Utils::RailsGeneratorRuntime.new(self)
      refute(defined?(HomeController))
      runtime.run_generator(ShopifyApp::Generators::HomeControllerGenerator)
      assert(defined?(HomeController))
      runtime.clear
      refute(defined?(HomeController))
    end

    test "generates and clear classes in session" do
      Utils::RailsGeneratorRuntime.with_session(self, is_embedded: true) do |runtime|
        refute(defined?(HomeController))
        runtime.run_generator(ShopifyApp::Generators::HomeControllerGenerator)
        assert(defined?(HomeController))
      end

      refute(defined?(HomeController))
    end
  end
end
