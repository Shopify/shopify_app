# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"

class LocalizationController < ActionController::Base
  include ShopifyApp::Localization

  before_action :set_locale

  def index
    head(:ok)
  end
end

class LocalizationTest < ActionController::TestCase
  tests LocalizationController

  setup do
    I18n.available_locales = [:en, :de, :es, :ja, :fr]
  end

  test "falls back to I18n.default if locale param is not present" do
    I18n.default_locale = :ja

    with_test_routes do
      get :index
      assert_equal :ja, I18n.locale
    end
  end

  test "set I18n.locale to passed locale param" do
    with_test_routes do
      get :index, params: { locale: "de" }
      assert_equal :de, I18n.locale
    end
  end

  test "falls back to I18n.default if locale is not supported" do
    I18n.default_locale = :en

    with_test_routes do
      get :index, params: { locale: "invalid_locale" }
      assert_equal :en, I18n.locale
    end
  end

  private

  def with_test_routes
    with_routing do |set|
      set.draw do
        get "/locale" => "localization#index"
      end
      yield
    end
  end
end
