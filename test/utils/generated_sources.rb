# frozen_string_literal: true

require "test_helper"
require "test_helpers/fake_session_storage"

module Utils
  class GeneratedSources
    ROOT = "test/.generated"

    def initialize(test_class)
      raise "Caller must provide an instance of a test to Utils::GeneratedSources.new" if test_class.nil?
      Utils::GeneratedSources.clear_generated_source_folder_on_first_instance
      @classes = []
      @destination = File.join(ROOT, "#{test_class.class_name}/#{test_class.method_name}")
    end

    def run_generator(generator_class, additional_args = [])
      suppress_output do
        generator_class.start(
          additional_args + ["--skip-bundle", "--skip-bootsnap"],
          { destination_root: destination }
        )
      end
    end

    def load_generated_classes(relative_path)
      load_classes(File.join(destination, relative_path))
    end

    def load_classes(path)
      generates_classes do
        load(path)
      end
    end

    def clear
      classes.each { |c| Object.send(:remove_const, c) }
      classes.clear
    end

    def controller(controller_class)
      controller_instance = controller_class.new

      if controller_instance.respond_to?(:current_shopify_session)
        def controller_instance.current_shopify_session
          ShopifyAPI::Auth::Session.new(shop: "my-shop")
        end
      end

      controller_instance
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

      def with_session(test_class, &block)
        WebMock.enable!

        ShopifyAPI::Context.setup(
          api_key: "API_KEY",
          api_secret_key: "API_SECRET_KEY",
          api_version: "unstable",
          host_name: "app-address.com",
          scope: ["scope1", "scope2"],
          is_private: false,
          is_embedded: false,
          session_storage: TestHelpers::FakeSessionStorage.new,
          user_agent_prefix: nil
        )

        sources = Utils::GeneratedSources.new(test_class)
        block.call(sources)
      ensure
        WebMock.reset!
        WebMock.disable!
        sources&.clear
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
