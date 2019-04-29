$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require "shopify_app/version"

Gem::Specification.new do |s|
  s.name        = "shopify_app"
  s.version     = ShopifyApp::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = "Shopify"
  s.summary     = %q{This gem is used to get quickly started with the Shopify API}

  s.required_ruby_version = ">= 2.3.1"

  s.add_runtime_dependency('browser_sniffer', '~> 1.1.0')
  s.add_runtime_dependency('rails', '>= 5.0.0')
  s.add_runtime_dependency('shopify_api', '>= 7.0.0')
  s.add_runtime_dependency('omniauth-shopify-oauth2', '~> 2.1.0')

  s.add_development_dependency('rake')
  s.add_development_dependency('byebug')
  s.add_development_dependency('sqlite3', '~> 1.3.6')
  s.add_development_dependency('minitest')
  s.add_development_dependency('mocha')

  s.files         = `git ls-files`.split("\n").reject { |f| f.match(%r{^(test|example)/}) }
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.require_paths = ["lib"]
end
