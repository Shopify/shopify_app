require 'rails/generators'

class ShopifyAppGenerator < Rails::Generators::Base
  argument :api_key, :type => :string, :required => true
  argument :secret, :type => :string, :required => true
  
  class_option :skip_routes, :type => :boolean, :default => false, :desc => 'pass true to skip route generation'
  
  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end
  
  def copy_files
    directory 'app'
    directory 'config'
    directory 'public'
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
