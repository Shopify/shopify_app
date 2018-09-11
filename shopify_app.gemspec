# -*- encoding: utf-8 -*-
# stub: shopify_app 8.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "shopify_app".freeze
  s.version = "8.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shopify".freeze]
  s.date = "2018-09-14"
  s.files = [".github/ISSUE_TEMPLATE.md".freeze, ".gitignore".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "app/assets/javascripts/shopify_app/itp_polyfill.js".freeze, "app/assets/javascripts/shopify_app/redirect.js".freeze, "app/controllers/shopify_app/authenticated_controller.rb".freeze, "app/controllers/shopify_app/sessions_controller.rb".freeze, "app/controllers/shopify_app/webhooks_controller.rb".freeze, "app/views/shopify_app/sessions/enable_cookies.html.erb".freeze, "app/views/shopify_app/sessions/new.html.erb".freeze, "app/views/shopify_app/shared/redirect.html.erb".freeze, "config/locales/de.yml".freeze, "config/locales/en.yml".freeze, "config/locales/es.yml".freeze, "config/locales/fr.yml".freeze, "config/locales/ja.yml".freeze, "config/routes.rb".freeze, "docs/Quickstart.md".freeze, "docs/Releasing.md".freeze, "docs/Troubleshooting.md".freeze, "images/app-proxy-screenshot.png".freeze, "lib/generators/shopify_app/add_after_authenticate_job/add_after_authenticate_job_generator.rb".freeze, "lib/generators/shopify_app/add_after_authenticate_job/templates/after_authenticate_job.rb".freeze, "lib/generators/shopify_app/add_webhook/add_webhook_generator.rb".freeze, "lib/generators/shopify_app/add_webhook/templates/webhook_job.rb".freeze, "lib/generators/shopify_app/app_proxy_controller/app_proxy_controller_generator.rb".freeze, "lib/generators/shopify_app/app_proxy_controller/templates/app_proxy_controller.rb".freeze, "lib/generators/shopify_app/app_proxy_controller/templates/app_proxy_route.rb".freeze, "lib/generators/shopify_app/app_proxy_controller/templates/index.html.erb".freeze, "lib/generators/shopify_app/controllers/controllers_generator.rb".freeze, "lib/generators/shopify_app/home_controller/home_controller_generator.rb".freeze, "lib/generators/shopify_app/home_controller/templates/home_controller.rb".freeze, "lib/generators/shopify_app/home_controller/templates/index.html.erb".freeze, "lib/generators/shopify_app/home_controller/templates/shopify_app_ready_script.html.erb".freeze, "lib/generators/shopify_app/install/install_generator.rb".freeze, "lib/generators/shopify_app/install/templates/_flash_messages.html.erb".freeze, "lib/generators/shopify_app/install/templates/embedded_app.html.erb".freeze, "lib/generators/shopify_app/install/templates/omniauth.rb".freeze, "lib/generators/shopify_app/install/templates/shopify_app.rb".freeze, "lib/generators/shopify_app/install/templates/shopify_provider.rb".freeze, "lib/generators/shopify_app/routes/routes_generator.rb".freeze, "lib/generators/shopify_app/routes/templates/routes.rb".freeze, "lib/generators/shopify_app/shop_model/shop_model_generator.rb".freeze, "lib/generators/shopify_app/shop_model/templates/db/migrate/create_shops.erb".freeze, "lib/generators/shopify_app/shop_model/templates/shop.rb".freeze, "lib/generators/shopify_app/shop_model/templates/shops.yml".freeze, "lib/generators/shopify_app/shopify_app_generator.rb".freeze, "lib/generators/shopify_app/views/views_generator.rb".freeze, "lib/shopify_app.rb".freeze, "lib/shopify_app/configuration.rb".freeze, "lib/shopify_app/controller_concerns/app_proxy_verification.rb".freeze, "lib/shopify_app/controller_concerns/embedded_app.rb".freeze, "lib/shopify_app/controller_concerns/localization.rb".freeze, "lib/shopify_app/controller_concerns/login_protection.rb".freeze, "lib/shopify_app/controller_concerns/webhook_verification.rb".freeze, "lib/shopify_app/engine.rb".freeze, "lib/shopify_app/jobs/scripttags_manager_job.rb".freeze, "lib/shopify_app/jobs/webhooks_manager_job.rb".freeze, "lib/shopify_app/managers/scripttags_manager.rb".freeze, "lib/shopify_app/managers/webhooks_manager.rb".freeze, "lib/shopify_app/session/in_memory_session_store.rb".freeze, "lib/shopify_app/session/session_repository.rb".freeze, "lib/shopify_app/session/session_storage.rb".freeze, "lib/shopify_app/utils.rb".freeze, "lib/shopify_app/version.rb".freeze, "shipit.rubygems.yml".freeze, "shopify_app.gemspec".freeze, "translation.yml".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.1".freeze)
  s.rubygems_version = "2.7.6".freeze
  s.summary = "This gem is used to get quickly started with the Shopify API".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>.freeze, [">= 5.0.0"])
      s.add_runtime_dependency(%q<shopify_api>.freeze, [">= 4.3.5"])
      s.add_runtime_dependency(%q<omniauth-shopify-oauth2>.freeze, ["~> 1.2.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rails>.freeze, [">= 5.0.0"])
      s.add_dependency(%q<shopify_api>.freeze, [">= 4.3.5"])
      s.add_dependency(%q<omniauth-shopify-oauth2>.freeze, ["~> 1.2.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>.freeze, [">= 5.0.0"])
    s.add_dependency(%q<shopify_api>.freeze, [">= 4.3.5"])
    s.add_dependency(%q<omniauth-shopify-oauth2>.freeze, ["~> 1.2.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
  end
end
