# frozen_string_literal: true

require "open3"

module Utils
  class GeneratedSources
    def initialize(destination: "test/tmp")
      @classes = []
      @destination = destination
      FileUtils.rm_rf(destination)
    end

    def run_generator(generator_class)
      suppress_output do
        generator_class.start(["--skip-bundle", "--skip-bootsnap"], { destination_root: destination })
      end
    end

    def load_generated_classes(relative_path)
      generates_classes do
        load(File.join(destination, relative_path))
      end
    end

    def eval_source(source)
      generates_classes do
        eval(source)
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

    def suppress_output(&block)
      original_stderr = $stderr.clone
      original_stdout = $stdout.clone
      $stderr.reopen(File.new('/dev/null', 'w'))
      $stdout.reopen(File.new('/dev/null', 'w'))
      block.call
    ensure
      $stdout.reopen(original_stdout)
      $stderr.reopen(original_stderr)
    end
  end
end
