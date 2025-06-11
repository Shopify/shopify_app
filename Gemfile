# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in shopify_app.gemspec
gemspec

# Local development dependency
gem "shopify_app_ai", path: "/Users/lizkenyib/workspace/ai-navtive-packages/shopify-app-packages/packages/ruby"

gem "rails-controller-testing", group: :test
gem "rails", "< 7" # temporary: https://github.com/Shopify/shopify_app/pull/1561

group :rubocop do
  gem "rubocop-shopify", require: false
end
