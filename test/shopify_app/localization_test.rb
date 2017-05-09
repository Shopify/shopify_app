require 'test_helper'
require 'action_controller'
require 'action_controller/base'

class LocalizationController < ActionController::Base
  include ShopifyApp::Localization

  before_action :set_locale

  def index
    render text: I18n.locale
  end
end

class LocalizationTest < ActionController::TestCase
  tests LocalizationController

  test "falls back to I18n.default if locale param is not present" do
    I18n.available_locales = [:en, :de, :es, :ja, :fr]
    I18n.default_locale = :ja

    with_test_routes do
      get :index
      assert 'ja', response.body
    end
  end

  test "set I18n.locale to passed locale param" do
    I18n.available_locales = [:en, :de, :es, :ja, :fr]

    with_test_routes do
      get :index, locale: 'de'
      assert 'de', response.body
    end
  end

  test "falls back to I18n.default if locale is not supported" do
    I18n.available_locales = [:en, :de, :es, :ja, :fr]
    I18n.default_locale = :en

    with_test_routes do
      get :index, locale: 'cu'
      assert 'en', response.body
    end
  end

  private

  def with_test_routes
    with_routing do |set|
      set.draw do
        get '/locale' => 'localization#index'
      end
      yield
    end
  end
end
