# Stolen from http://github.com/technoweenie/restful-authentication/tree/master/generators/authenticated/lib
# Modified by Dennis Theisen
# Thanks a lot !
Rails::Generator::Commands::Create.class_eval do
  def route(name, path, options = {})    
    cmd = "map.#{name} '#{path}', :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]
    
    add_route(cmd)
  end

  def route_root(options = {})    
    cmd = "map.root :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]
    
    add_route(cmd)
  end
     
  private
  
  def add_route(cmd)
    sentinel = 'ActionController::Routing::Routes.draw do |map|'

    logger.route(cmd)
    unless options[:pretend]      
      if not File.read("#{RAILS_ROOT}/config/routes.rb").include?(cmd)
      
        gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
          "#{match}\n  #{cmd}"
        end
      end
    end    
  end
end
 
Rails::Generator::Commands::Destroy.class_eval do
  def route(name, path, options = {})
    cmd = "map.#{name} '#{path}', :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]
    
    remove_route(cmd)
  end

  def route_root(name, path, options = {})
    cmd = "map.root :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]    
    
    remove_route(cmd)
  end
  
  def remove_route(cmd)
    logger.route(cmd)
    unless options[:pretend]      
      gsub_file 'config/routes.rb', /\n\s*(#{cmd})/mi, ''    
    end
  end
end
 
Rails::Generator::Commands::List.class_eval do
  def route(name, path, options = {})
    cmd = "map.#{name} '#{path}', :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]
    
    logger.route(cmd)
  end
  
  def route_root(name, path, options = {})
    cmd = "map.root :controller => '#{options[:controller]}'"
    cmd << ", :action => '#{options[:action]}'" if options[:action]    
    
    logger.route(cmd)
  end
  
end