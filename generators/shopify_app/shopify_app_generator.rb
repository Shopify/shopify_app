require File.expand_path(File.dirname(__FILE__) + "/lib/insert_routes.rb")

class ShopifyAppGenerator < Rails::Generator::Base
  
  PLUGIN_NAME = 'shopify_app'   
  TEMPLATES = ['shopify.yml']
  
  attr_accessor :api_key, :secret
  
  def initialize(*runtime_args)
    super(*runtime_args)
    usage if args.size < 2
    
    @api_key = args[0]
    @secret = args[1]
  end
  
  def manifest
    
    record do |m|           
                                               
      base = File.dirname(__FILE__) + '/templates/'       
      
      Dir[base + '**/*'].each do |file|
        relative_file = file.sub(base, '')

        
        if File.directory?(file)          
          if not File.exist?("#{RAILS_ROOT}/#{relative_file}")
            m.directory relative_file
          end
          
          next          
        end
            
        if TEMPLATES.include?(File.basename(relative_file))
          m.template relative_file, relative_file          
        else
          m.file relative_file, relative_file
        end
        
      end


      unless options[:skip_route]
        m.route_root :controller => 'home'
      end            

      # delete public/index.html
      File.delete "#{RAILS_ROOT}/public/index.html" if File.exist?("#{RAILS_ROOT}/public/index.html")
            
      # Display Readme
      m.readme '../README'
      

    end
  end
  
  
protected

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--do-nothing", "Don't generate anything at all.") { |v| options[:do_nothing] = v }
    opt.on("--skip-route", "Don't add any routes.") { |v| options[:skip_route] = v }
  end

  def banner
    <<-EOS
Creates a login controller and a dashboard controller showing basic information about a shop.

USAGE: #{$0} #{spec.name} API_Key Secret [options]
EOS
  end
  
end
