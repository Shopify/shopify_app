# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_controller/base"
require "action_view/testing/resolvers"

class FrameAncestorsController < ActionController::Base
  include ShopifyApp::FrameAncestors

  def index
    head :ok
  end
end

class FrameAncestorsControllerTest < ActionController::TestCase
  tests FrameAncestorsController

  test "conent security policy headers are set" do
    with_test_routes do
      get :index
    end
  end

  private

  def with_test_routes
    with_routing do |set|
      set.draw do
        get "/frames" => "frame_ancestors#index"
      end
      yield
    end
  end
end
