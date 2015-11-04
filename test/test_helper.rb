# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
require 'rails/test_help'
require 'mocha/setup'
require 'byebug'

if ENV['CI'] == 'true'
    require 'simplecov'
    SimpleCov.start

    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
