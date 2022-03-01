# frozen_string_literal: true

require "test_helper"
require "test_helpers/fake_session_storage"

module Utils
  class RailsGeneratorRuntime
    ROOT = "test/.generated"

    def initialize(test_class)
      raise "Caller must provide an instance of a test to Utils::RailsGeneratorRuntime.new" if test_class.nil?
      Utils::RailsGeneratorRuntime.clear_generated_source_folder_on_first_instance
      @classes = []
      @destination = File.join(ROOT, "#{test_class.class_name}/#{test_class.method_name}")
    end

    def run_generator(generator_class, additional_args = [])
      new_files = generates_files do
        suppress_output do
          generator_class.start(
            additional_args + ["--skip-bundle", "--skip-bootsnap"],
            { destination_root: destination }
          )
        end
      end

      generates_classes do
        new_files.each { |file| load(file) }
      end
    end

    def clear
      classes.each { |c| Object.send(:remove_const, c) }
      classes.clear
    end

    private

    attr_reader :classes
    attr_reader :destination

    def generates_classes(&block)
      before_block = Object.constants
      block.call
      after_block = Object.constants
      new_classes = after_block - before_block
      classes.concat(new_classes)
    end

    def generates_files(&block)
      before_block = generated_files
      block.call
      after_block = generated_files
      after_block - before_block
    end

    def generated_files
      Dir.glob(File.join(destination, "**/*"))
        .reject { |f| File.directory?(f) }
        .select { |f| File.extname(f) == ".rb" }
    end

    def suppress_output(&block)
      original_stderr = $stderr.clone
      original_stdout = $stdout.clone
      $stderr.reopen(File.new("/dev/null", "w"))
      $stdout.reopen(File.new("/dev/null", "w"))
      block.call
    ensure
      $stdout.reopen(original_stdout)
      $stderr.reopen(original_stderr)
    end

    class << self
      @initialized = false

      def with_session(test_class, is_embedded: false, is_private: false, &block)
        WebMock.enable!
        original_embedded_app = ShopifyApp.configuration.embedded_app
        ShopifyApp.configuration.embedded_app = false unless is_embedded
        ShopifyAPI::Context.setup(
          api_key: "API_KEY",
          api_secret_key: "API_SECRET_KEY",
          api_version: "unstable",
          host_name: "app-address.com",
          scope: ["scope1", "scope2"],
          is_private: is_private,
          is_embedded: is_embedded,
          session_storage: TestHelpers::FakeSessionStorage.new,
          user_agent_prefix: nil
        )
        ShopifyAPI::Context.activate_session(ShopifyAPI::Auth::Session.new(shop: "my-shop"))

        runtime = Utils::RailsGeneratorRuntime.new(test_class)
        block.call(runtime)
      ensure
        WebMock.reset!
        WebMock.disable!
        ShopifyApp.configuration.embedded_app = original_embedded_app
        ShopifyAPI::Context.deactivate_session
        runtime&.clear
      end

      def clear_generated_source_folder_on_first_instance
        return if @initialized
        @initialized = true
        FileUtils.rm_rf(ROOT)
        FileUtils.mkdir_p(ROOT)
        FileUtils.touch(File.join(ROOT, ".keep"))
      end
    end
  end
end
