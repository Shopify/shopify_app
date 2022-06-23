# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in shopify_app.gemspec
gemspec

gem "rails-controller-testing", group: :test

group :rubocop do
  gem "rubocop-shopify", require: false
end

gem 'shopify_api', git: 'git@github.com:Shopify/shopify_api.git', branch: 'add-old-api-secret-key-to-context'
