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
  
  def add_routes
    unless options[:skip_routes]
      route "match 'login/logout'       => 'login#logout'"
      route "match 'login/finalize'     => 'login#finalize'"
      route "match 'login/authenticate' => 'login#authenticate'"
      route "match 'login'              => 'login#index'"
      route "match 'design'             => 'home#design'"
      route "match 'welcome'            => 'home#welcome'"
      route "root :to                   => 'home#index'"
    end
  end
  
  def display_readme
    readme '../README'
  end
end
