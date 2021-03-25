# frozen_string_literal: true
$LOAD_PATH.push(File.expand_path('../lib', __FILE__))
require "shopify_app/version"

Gem::Specification.new do |s|
  s.name        = "shopify_app"
  s.version     = ShopifyApp::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = "Shopify"
  s.summary     = 'This gem is used to get quickly started with the Shopify API'

  s.required_ruby_version = ">= 2.5"

  s.metadata['allowed_push_host'] = 'https://rubygems.org'

  s.add_runtime_dependency('browser_sniffer', '~> 1.2.2')
  # s.add_runtime_dependency('rails', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('actioncable', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('actionmailer', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('actionpack', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('actionview', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('activejob', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('activerecord', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('activesupport', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('railties', '> 5.2.1', '< 6.1')
  s.add_runtime_dependency('sprockets-rails', '~> 3.2.2')


  s.add_runtime_dependency('shopify_api', '~> 9.4')
  s.add_runtime_dependency('omniauth-shopify-oauth2', '~> 2.2.2')
  s.add_runtime_dependency('jwt', '~> 2.2.1')
  s.add_runtime_dependency('redirect_safely', '~> 1.0')

  s.add_development_dependency('rake')
  s.add_development_dependency('byebug')
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-nav')
  s.add_development_dependency('pry-stack_explorer')
  s.add_development_dependency('rb-readline')
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('minitest')
  s.add_development_dependency('mocha')
  s.add_development_dependency('webmock')

  s.files         = %x(git ls-files).split("\n").reject { |f| f.match(%r{^(test|example)/}) }
  s.test_files    = %x(git ls-files -- {test}/*).split("\n")
  s.require_paths = ["lib"]
end
