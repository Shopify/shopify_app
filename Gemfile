# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in shopify_app.gemspec
gemspec

gem "rails-controller-testing", group: :test
gem "rails", "< 7" # temporary: https://github.com/Shopify/shopify_app/pull/1561

if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new("3.1")
  gem "net-imap", require: false
  gem "net-pop", require: false
  gem "net-smtp", require: false
end

group :rubocop do
  gem "rubocop-shopify", require: false
end
