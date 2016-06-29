require 'test_helper'

class ShopifyApp::CarrierServicesManagerTest < ActiveSupport::TestCase

  setup do
    ShopifyApp.configure do |config|
      config.carrier_services = [
        {
          name: "Example Carrier Service 1",
          active: true,
          service_discovery: true,
          callback_url: "https://example-app.com/some_url_1"
        },
        {
          name: "Example Carrier Service 2",
          active: true,
          service_discovery: true,
          callback_url: "https://example-app.com/some_url_2"
        }
      ]
    end

    @manager = ShopifyApp::CarrierServicesManager.new
  end

  test "#create_carrier_services makes calls to create carrier_services" do
    ShopifyAPI::CarrierService.stubs(all: [])

    expect_carrier_service_creation('Example Carrier Service 1')
    expect_carrier_service_creation('Example Carrier Service 2')

    @manager.create_carrier_services
  end

  test "#create_carrier_services when creating a carrier_service fails, raises an error" do
    ShopifyAPI::CarrierService.stubs(all: [])
    carrier_service = stub(
      persisted?: false,
      errors: stub(full_messages: stub(to_sentence: 'There were errors'))
    )
    ShopifyAPI::CarrierService.stubs(create: carrier_service)

    assert_raise ShopifyApp::CarrierServicesManager::CreationFailed do
      @manager.create_carrier_services
    end
  end

  test "#create_carrier_services when creating a carrier_service fails and the carrier_service exists, do not raise an error" do
    carrier_service = stub(persisted?: false)
    carrier_services = [
      stub(name: "Example Carrier Service 1"),
      stub(name: "Example Carrier Service 2"),
    ]
    ShopifyAPI::CarrierService.stubs(create: carrier_service, all: carrier_services)

    assert_nothing_raised ShopifyApp::CarrierServicesManager::CreationFailed do
      @manager.create_carrier_services
    end
  end

  test "#recreate_carrier_services! destroys all carrier_services and recreates" do
    @manager.expects(:destroy_carrier_services)
    @manager.expects(:create_carrier_services)

    @manager.recreate_carrier_services!
  end

  test "#destroy_carrier_services makes calls to destroy carrier_services" do
    ShopifyAPI::CarrierService.stubs(:all).returns(Array.wrap(all_mock_carrier_services.first))
    ShopifyAPI::CarrierService.expects(:delete).with(all_mock_carrier_services.first.id)

    @manager.destroy_carrier_services
  end

  test "#destroy_carrier_services does not destroy carrier_services that do not have a matching address" do
    ShopifyAPI::CarrierService.stubs(:all).returns([
      stub(name: 'Some Other Carrier Service', id: 7214109)
    ])
    ShopifyAPI::CarrierService.expects(:delete).never

    @manager.destroy_carrier_services
  end

  private

  def expect_carrier_service_creation(name)
    stub_carrier_service = stub(persisted?: true)
    ShopifyAPI::CarrierService.expects(:create).with(has_entry(name: name)).returns(stub_carrier_service)
  end

  def all_mock_carrier_services
    [
      stub(
        id: 1,
        name: "Example Carrier Service 1",
      ),
      stub(
        id: 2,
        name: "Example Carrier Service 2",
      ),
    ]
  end
end
