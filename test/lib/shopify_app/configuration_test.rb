require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    Rails.stubs(:env).returns('development')
    Rails.stubs(:root).returns(File.expand_path('../..', File.dirname(__FILE__)))
  end

  def config_file(filename)
    filepath = File.expand_path("../../config/#{filename}", File.dirname(__FILE__))
  end

  def test_define_method_creates_readers
    config = ShopifyApp::Configuration.new
    config.respond_to?(:api_key)
    config.respond_to?(:secret)
    config.respond_to?(:myshopify_domain)
  end

  def test_defaults_to_empty_string
    config = ShopifyApp::Configuration.new(config_file: config_file('empty_config_file.yml'))

    assert_equal '', config.api_key
    assert_equal '', config.secret
    assert_equal '', config.myshopify_domain
  end

  def test_environment_has_precedence_over_common
    config = ShopifyApp::Configuration.new(config_file: config_file('development_config_file.yml'))

    assert_equal 'development key', config.api_key
    assert_equal 'development secret', config.secret
    assert_equal 'myshopify.com', config.myshopify_domain
  end

  def test_rails_has_precedence_over_environment
    config = ShopifyApp::Configuration.new(config_file: config_file('development_config_file.yml'))

    assert_equal 'development key', config.api_key
    assert_equal 'development secret', config.secret
    assert_equal 'myshopify.com', config.myshopify_domain

    config.api_key = 'rails key'
    config.secret = 'rails secret'
    config.myshopify_domain = 'example.com'

    assert_equal 'rails key', config.api_key
    assert_equal 'rails secret', config.secret
    assert_equal 'example.com', config.myshopify_domain
  end

  def test_env_has_precedence_over_rails
    config = ShopifyApp::Configuration.new
    config.api_key = 'rails key'
    config.secret = 'rails secret'
    config.myshopify_domain = 'myshopify.com'

    assert_equal 'rails key', config.api_key
    assert_equal 'rails secret', config.secret
    assert_equal 'myshopify.com', config.myshopify_domain

    ENV.expects(:[]).with('SHOPIFY_APP_API_KEY').returns('env key')
    ENV.expects(:[]).with('SHOPIFY_APP_SECRET').returns('env secret')
    ENV.expects(:[]).with('SHOPIFY_APP_MYSHOPIFY_DOMAIN').returns('example.com')

    assert_equal 'env key', config.api_key
    assert_equal 'env secret', config.secret
    assert_equal 'example.com', config.myshopify_domain
  end

  def test_reads_config_from_default_config_file
    config = ShopifyApp::Configuration.new
    assert_equal 'api key from default file', config.api_key
    assert_equal 'secret from default file', config.secret
    assert_equal 'myshopify.com', config.myshopify_domain
  end

  def test_reads_config_from_specified_config_file
    config = ShopifyApp::Configuration.new(config_file: config_file('other_config_file.yml'))
    assert_equal 'api key from other file', config.api_key
    assert_equal 'secret from other file', config.secret
    assert_equal 'example.com', config.myshopify_domain
  end

  def test_handles_missing_config_file
    config = ShopifyApp::Configuration.new(config_file: config_file('missing_config_file.yml'))
    assert_equal '', config.api_key
    assert_equal '', config.secret
    assert_equal '', config.myshopify_domain
  end
end
