require 'rails/generators'

class ShopifyAppGenerator < Rails::Generators::Base
  argument :api_key, :type => :string, :required => false
  argument :secret, :type => :string, :required => false
  
  class_option :skip_routes, :type => :boolean, :default => false, :desc => 'pass true to skip route generation'
  
  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end
  
  def copy_files
    directory 'app'
    directory 'public'
    directory 'config'
  end
  
  def remove_static_index
    remove_file 'public/index.html'
  end
  
  def add_config_variables
    api_key_str = api_key.nil? ? "ENV['SHOPIFY_API_KEY']" : api_key.inspect
    api_secret_str = secret.nil? ? "ENV['SHOPIFY_API_SECRET']" : secret.inspect
    
    inject_into_file 'config/application.rb', <<-DATA, :after => "class Application < Rails::Application\n"
    
    # Shopify API connection credentials:
    config.shopify.api_key = #{api_key_str}
    config.shopify.secret = #{api_secret_str}
    
    DATA
  end

  def add_bootstrap_gem
    gem_group :development, :test do
      gem "less-rails-bootstrap"
      gem 'therubyracer', :platforms => :ruby
    end
  end
  
  def add_routes
    unless options[:skip_routes]
      route_without_newline "root :to => 'home#index'"
      route "end"
      route_without_newline "  delete 'logout' => :destroy"
      route_without_newline "  get 'auth/shopify/callback' => :show"
      route_without_newline "  post 'login' => :create"
      route_without_newline "  get 'login' => :new"
      route_without_newline "controller :sessions do"
      route "match 'design' => 'home#design'"
      route_without_newline "match 'welcome' => 'home#welcome'"
    end
  end
  
  def display_readme
    `bundle install`
    readme '../README'
  end
  
  private
  
  def route_without_newline(routing_code)
    sentinel = /\.routes\.draw do(?:\s*\|map\|)?\s*$/
    inject_into_file 'config/routes.rb', "\n  #{routing_code}", { after: sentinel, verbose: false }
  end  
end
