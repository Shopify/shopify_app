require 'test_helper'

class ConfigurationTest < MiniTest::Unit::TestCase
  def setup
    Rails.stubs(:env).returns('development')
    Rails.stubs(:root).returns(File.expand_path('../..', File.dirname(__FILE__)))

    @common_config_data = {
      'common' => {
        'api_key' => 'common key',
        'secret' => 'common secret'
      }
    }

    @development_config_data = @common_config_data.merge({
      'development' => {
        'api_key' => 'development key',
        'secret' => 'development secret'
      }
    })
  end

  def test_define_method_creates_readers
    config = ShopifyApp::Configuration.new
    config.respond_to?(:api_key)
    config.respond_to?(:secret)
  end

  def test_defaults_to_empty_string
    ShopifyApp::Configuration.stubs(:load_config).returns({})
    config = ShopifyApp::Configuration.new
    assert_equal '', config.api_key
    assert_equal '', config.secret
  end

  def test_environment_has_precedence_over_common
    ShopifyApp::Configuration.stubs(:load_config).returns(@common_config_data)
    config = ShopifyApp::Configuration.new

    assert_equal 'common key', config.api_key
    assert_equal 'common secret', config.secret

    ShopifyApp::Configuration.stubs(:load_config).returns(@development_config_data)
    config = ShopifyApp::Configuration.new

    assert_equal 'development key', config.api_key
    assert_equal 'development secret', config.secret
  end

  def test_rails_has_precedence_over_environment
    ShopifyApp::Configuration.stubs(:load_config).returns(@development_config_data)
    config = ShopifyApp::Configuration.new

    assert_equal 'development key', config.api_key
    assert_equal 'development secret', config.secret

    config.instance_variable_set '@api_key', 'rails key'
    config.instance_variable_set '@secret', 'rails secret'

    assert_equal 'rails key', config.api_key
    assert_equal 'rails secret', config.secret
  end

  def test_env_has_precedence_over_rails
    config = ShopifyApp::Configuration.new
    config.instance_variable_set '@api_key', 'rails key'
    config.instance_variable_set '@secret', 'rails secret'

    assert_equal 'rails key', config.api_key
    assert_equal 'rails secret', config.secret

    ENV.expects(:[]).with('SHOPIFY_APP_API_KEY').returns('env key')
    ENV.expects(:[]).with('SHOPIFY_APP_SECRET').returns('env secret')

    assert_equal 'env key', config.api_key
    assert_equal 'env secret', config.secret
  end

  def test_load_config_reads_config_from_file
    config = ShopifyApp::Configuration.new
    assert_equal 'api key from file', config.api_key
    assert_equal 'secret from file', config.secret
  end
end
