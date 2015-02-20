class ShopifyApp::Configuration
  VALID_KEYS = [:api_key, :secret, :myshopify_domain]
  attr_writer *VALID_KEYS

  def initialize(params={})
    self.params = default_params.merge(params)
  end

  VALID_KEYS.each do |meth|
    define_method meth do
      meth = meth.to_s
      config_from_env(meth) || config_from_rails(meth) || config_from_file(meth) || ''
    end
  end

  private

  attr_accessor :params

  def config_from_env(meth)
    ENV["SHOPIFY_APP_#{meth.upcase}"]
  end

  def config_from_rails(meth)
    instance_variable_get("@#{meth}")
  end

  def config_from_file(meth)
    @config_file ||= load_config
    @config_file[Rails.env].try(:[], meth) || @config_file['common'].try(:[], meth)
  end

  def load_config
    File.exist?(config_filepath) ? YAML.load_file(config_filepath) : {}
  end

  def config_filepath
    params[:config_file]
  end

  def default_params
    {
      config_file: File.join(Rails.root, 'config', 'shopify_app.yml')
    }
  end
end
