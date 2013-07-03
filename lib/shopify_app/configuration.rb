class ShopifyApp::Configuration
  VALID_KEYS = [:api_key, :secret]
  attr_writer *VALID_KEYS
  
  def initialize
    @config_file = YAML.load_file(File.join(Rails.root, 'config', 'shopify_app.yml')) || {}
  end
  
  VALID_KEYS.each do |meth|
    define_method meth do
      meth = meth.to_s
      config_from_env(meth) || config_from_rails(meth) || config_from_file(meth) || ''
    end
  end
  
  private
  
  def config_from_env(meth)
    ENV["SHOPIFY_APP_#{meth.upcase}"]
  end
  
  def config_from_rails(meth)
    instance_variable_get("@#{meth}")
  end
  
  def config_from_file(meth)
    @config_file[Rails.env.to_s].try(:[], meth) || @config_file['common'].try(:[], meth)
  end
end
