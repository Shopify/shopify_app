# frozen_string_literal: true

require "test_helper"

class ShopifyApp::ScriptTagsManagerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @script_tags = [
      { cache: true, src: "https://example-app.com/fancy.js" },
      { cache: true, src: "https://example-app.com/foobar.js" },
      { cache: true, src: ->(domain) { "https://example-app.com/#{domain}-123.js" } },
    ]

    @script_tags_with_template_types = [
      { cache: true, src: "https://example-app.com/fancy.js", template_types: ["product", "collection"] },
      { cache: true, src: "https://example-app.com/foobar.js", template_types: ["index"] },
    ]

    @session = ShopifyAPI::Auth::Session.new(shop: "some-shop.myshopify.com")
    ShopifyAPI::Context.activate_session(@session)
    @manager = ShopifyApp::ScriptTagsManager.new(@script_tags, "example-app.com")

    # Mock the GraphQL client
    @mock_client = mock("GraphQLClient")
    @manager.stubs(:graphql_client).returns(@mock_client)
  end

  test "#create_script_tags creates each required script  tag" do
    # Mock empty script tags response
    mock_empty_script_tags_response

    # Expect GraphQL calls for each script tag creation
    expect_script_tag_creation("https://example-app.com/fancy.js")
    expect_script_tag_creation("https://example-app.com/foobar.js")
    expect_script_tag_creation("https://example-app.com/example-app.com-123.js")

    @manager.create_script_tags(session: @session)
  end

  test "#create_script_tags preserves dynamic src references" do
    # Mock empty script tags response
    empty_response = mock
    empty_response.stubs(:body).returns({
      "data" => {
        "scriptTags" => {
          "edges" => [],
        },
      },
    })

    # Mock successful creation responses
    success_response = mock
    success_response.stubs(:body).returns({
      "data" => {
        "scriptTagCreate" => {
          "scriptTag" => {
            "id" => "gid://shopify/ScriptTag/123",
            "src" => "https://example-app.com/script.js",
            "displayScope" => "ONLINE_STORE",
            "cache" => true,
          },
          "userErrors" => [],
        },
      },
    })

    # Set up the sequence of responses
    @mock_client.stubs(:query)
      .returns(empty_response)
      .then.returns(success_response)
      .then.returns(success_response)
      .then.returns(success_response)

    @manager.create_script_tags(session: @session)

    assert_equal 3, @manager.required_script_tags.length
    assert_respond_to @manager.required_script_tags.last[:src], :call
  end

  test "#create_script_tags raises CreationFailed when API returns errors" do
    # First mock the empty scripttags response for the initial check
    empty_response = mock
    empty_response.stubs(:body).returns({
      "data" => {
        "scriptTags" => {
          "edges" => [],
        },
      },
    })

    # Then mock the error response for the creation attempt
    error_response = mock
    error_response.stubs(:body).returns({
      "data" => {
        "scriptTagCreate" => {
          "scriptTag" => nil,
          "userErrors" => [
            { "field" => "src", "message" => "Error message" },
          ],
        },
      },
    })

    # Set up the sequence of responses
    @mock_client.stubs(:query).returns(empty_response).then.returns(error_response)

    e = assert_raise ::ShopifyApp::CreationFailed do
      @manager.create_script_tags(session: @session)
    end

    assert_equal "ScriptTag creation failed: src: Error message", e.message
  end

  test "#create_script_tags propagates exceptions from dynamic src" do
    # Mock the first two script tags to exist
    mock_script_tags_response([
      { "id" => "gid://shopify/ScriptTag/1", "src" => "https://example-app.com/fancy.js" },
      { "id" => "gid://shopify/ScriptTag/2", "src" => "https://example-app.com/foobar.js" },
    ])

    # Don't set any expectations on query since we'll raise an exception
    @mock_client.stubs(:query)

    @manager.required_script_tags.last[:src] = ->(_domain) { raise "oops!" }

    e = assert_raise do
      @manager.create_script_tags(session: @session)
    end

    assert_equal "oops!", e.message
  end

  test "#recreate_script_tags! destroys all script tags and recreates them" do
    @manager.expects(:destroy_script_tags).with(session: @session)
    @manager.expects(:create_script_tags).with(session: @session)

    @manager.recreate_script_tags!(session: @session)
  end

  test "#destroy_script_tags removes matching script tags" do
    # Mock existing script tags
    mock_script_tags_response([
      { "id" => "gid://shopify/ScriptTag/1", "src" => "https://example-app.com/fancy.js" },
    ])

    # Expect delete call
    expect_script_tag_deletion("gid://shopify/ScriptTag/1")

    @manager.destroy_script_tags(session: @session)
  end

  test "#destroy_script_tags handles dynamic src values correctly" do
    # Mock existing script tags
    mock_script_tags_response([
      { "id" => "gid://shopify/ScriptTag/3", "src" => "https://example-app.com/example-app.com-123.js" },
    ])

    # Expect delete call
    expect_script_tag_deletion("gid://shopify/ScriptTag/3")

    @manager.destroy_script_tags(session: @session)
  end

  test "#destroy_scripttags preserves dynamic src references" do
    # Mock existing script tags
    mock_script_tags_response([
      { "id" => "gid://shopify/ScriptTag/3", "src" => "https://example-app.com/example-app.com-123.js" },
    ])

    # Expect delete call
    expect_script_tag_deletion("gid://shopify/ScriptTag/3")

    @manager.destroy_script_tags(session: @session)
    assert_respond_to @manager.required_script_tags.last[:src], :call
  end

  test "#destroy_script_tags does not remove non-matching script tags" do
    # Mock existing script tags with non-matching src
    mock_script_tags_response([
      { "id" => "gid://shopify/ScriptTag/7214109", "src" => "http://something-or-the-other.com/badscript.js" },
    ])

    # No delete call should be made
    @mock_client.expects(:query).with(has_entry(variables: { id: "gid://shopify/ScriptTag/7214109" })).never

    @manager.destroy_script_tags(session: @session)
  end

  test ".queue enqueues a ScripttagsManagerJob with correct parameters" do
    # Configure the script_tags_manager_queue_name
    ShopifyApp.configuration.stubs(:script_tags_manager_queue_name).returns(:default)

    args = {
      shop_domain: "example-app.com",
      shop_token: "token",
      script_tags: [cache: true, src: "https://example-app.com/example-app.com-123.js"],
    }

    assert_enqueued_with(job: ShopifyApp::ScriptTagsManagerJob, args: [args]) do
      ShopifyApp::ScriptTagsManager.queue(args[:shop_domain], args[:shop_token], @script_tags[-1, 1])
    end
  end

  test "#create_script_tags skips creation when theme supports app blocks for all template types" do
    # Create manager with script tags that have template types
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags_with_template_types, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock theme response
    theme_response = mock
    theme_response.stubs(:body).returns({
      "data" => {
        "themes" => {
          "nodes" => [
            { "id" => "gid://shopify/OnlineStoreTheme/123", "name" => "Test Theme" },
          ],
        },
      },
    })

    # Mock all templates response (product, collection, index)
    all_templates_response = mock
    all_templates_response.stubs(:body).returns({
      "data" => {
        "theme" => {
          "files" => {
            "nodes" => [
              {
                "filename" => "templates/product.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-product","settings":{}}}}',
                },
              },
              {
                "filename" => "templates/collection.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-collection","settings":{}}}}',
                },
              },
              {
                "filename" => "templates/index.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-index","settings":{}}}}',
                },
              },
            ],
          },
        },
      },
    })

    # Mock all sections response with app block support
    all_sections_response = mock
    all_sections_response.stubs(:body).returns({
      "data" => {
        "theme" => {
          "files" => {
            "nodes" => [
              {
                "filename" => "sections/main-product.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "@app" } ] } {% endschema %}',
                },
              },
              {
                "filename" => "sections/main-collection.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "@app" } ] } {% endschema %}',
                },
              },
              {
                "filename" => "sections/main-index.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "@app" } ] } {% endschema %}',
                },
              },
            ],
          },
        },
      },
    })

    # Set up the sequence of responses for the GraphQL client
    # Now we only need 3 responses: theme, all templates, all sections
    @mock_client.stubs(:query).returns(theme_response).then
      .returns(all_templates_response).then
      .returns(all_sections_response)

    # No scripttag creation should be attempted
    @mock_client.expects(:query).with(has_entry(variables: has_key(:input))).never

    # Allow logging without capturing
    ShopifyApp::Logger.stubs(:info)

    manager.create_script_tags(session: @session)
  end

  test "#create_scripttags creates scripttags when theme doesn't support app blocks for all template types" do
    # Create manager with script tags that have template types
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags_with_template_types, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock theme response
    theme_response = mock
    theme_response.stubs(:body).returns({
      "data" => {
        "themes" => {
          "nodes" => [
            { "id" => "gid://shopify/OnlineStoreTheme/123", "name" => "Test Theme" },
          ],
        },
      },
    })

    # Mock all templates response (product, collection)
    all_templates_response = mock
    all_templates_response.stubs(:body).returns({
      "data" => {
        "theme" => {
          "files" => {
            "nodes" => [
              {
                "filename" => "templates/product.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-product","settings":{}}}}',
                },
              },
              {
                "filename" => "templates/collection.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-collection","settings":{}}}}',
                },
              },
              {
                "filename" => "templates/index.json",
                "body" => {
                  "content" => '{"sections":{"main":{"type":"main-index","settings":{}}}}',
                },
              },
            ],
          },
        },
      },
    })

    # Mock all sections response with one section NOT supporting app blocks
    all_sections_response = mock
    all_sections_response.stubs(:body).returns({
      "data" => {
        "theme" => {
          "files" => {
            "nodes" => [
              {
                "filename" => "sections/main-product.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "@app" } ] } {% endschema %}',
                },
              },
              {
                "filename" => "sections/main-collection.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "text" } ] } {% endschema %}',
                },
              },
              {
                "filename" => "sections/main-index.liquid",
                "body" => {
                  "content" => '{% schema %} { "blocks": [ { "type": "@app" } ] } {% endschema %}',
                },
              },
            ],
          },
        },
      },
    })

    # Mock empty script tags response
    empty_script_tags_response = mock
    empty_script_tags_response.stubs(:body).returns({
      "data" => {
        "scriptTags" => {
          "edges" => [],
        },
      },
    })

    # Set up the sequence of responses for the GraphQL client
    @mock_client.stubs(:query)
      .returns(theme_response)
      .then.returns(all_templates_response)
      .then.returns(all_sections_response)
      .then.returns(empty_script_tags_response)

    # Expect script tag creation calls
    expect_script_tag_creation("https://example-app.com/fancy.js")
    expect_script_tag_creation("https://example-app.com/foobar.js")

    manager.create_script_tags(session: @session)
  end

  test "#create_scripttags_skips_creation_when_theme_API_access_fails" do
    # Create manager with script tags that have template types
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags_with_template_types, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock theme response with error
    error_response = mock
    error_response.stubs(:body).returns({
      "errors" => [
        {
          "message" => "Access denied for themes field. Required access: `read_themes` access scope.",
          "locations" => [{ "line" => 2, "column" => 11 }],
          "path" => ["themes"],
          "extensions" => {
            "code" => "ACCESS_DENIED",
            "documentation" => "https://shopify.dev/api/usage/access-scopes",
            "requiredAccess" => "`read_themes` access scope.",
          },
        },
      ],
      "data" => { "themes" => nil },
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(error_response).once

    # No scripttag creation should be attempted
    @mock_client.expects(:query).with(has_entry(variables: has_key(:input))).never

    # Allow logging without capturing
    ShopifyApp::Logger.stubs(:info)
    ShopifyApp::Logger.stubs(:warn)

    manager.create_script_tags(session: @session)
  end

  test "#create_scripttags skips creation when active theme is empty" do
    # Create manager with script tags that have template types
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags_with_template_types, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock theme response with empty nodes array
    empty_theme_response = mock
    empty_theme_response.stubs(:body).returns({
      "data" => {
        "themes" => {
          "nodes" => [],
        },
      },
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(empty_theme_response).once

    # No scripttag creation should be attempted
    @mock_client.expects(:query).with(has_entry(variables: has_key(:input))).never

    # Allow logging without capturing
    ShopifyApp::Logger.stubs(:info)

    manager.create_script_tags(session: @session)
  end

  test "#create_scripttags skips creation when theme response has invalid structure" do
    # Create manager with script tags that have template types
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags_with_template_types, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock theme response with invalid structure
    invalid_response = mock
    invalid_response.stubs(:body).returns({
      "data" => {
        # Missing "themes" key
      },
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(invalid_response).once

    # No scripttag creation should be attempted
    @mock_client.expects(:query).with(has_entry(variables: has_key(:input))).never

    # Allow logging without capturing
    ShopifyApp::Logger.stubs(:info)
    ShopifyApp::Logger.stubs(:warn)

    manager.create_script_tags(session: @session)
  end

  test "#fetch_active_theme raises InvalidGraphqlRequestError when GraphQL errors are present" do
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock GraphQL error response
    error_response = mock
    error_response.stubs(:body).returns({
      "errors" => [
        {
          "message" => "GraphQL error message",
          "locations" => [{ "line" => 2, "column" => 11 }],
          "path" => ["themes"],
        },
      ],
      "data" => nil,
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(error_response).once

    # Stub the rescue block to verify the error is raised before it's caught
    ShopifyApp::Logger.expects(:warn).with("Failed to fetch active theme: GraphQL error message")

    # The method will return nil due to the rescue block
    assert_nil manager.send(:fetch_active_theme)
  end

  test "#fetch_json_templates raises InvalidGraphqlRequestError when GraphQL errors are present" do
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock GraphQL error response
    error_response = mock
    error_response.stubs(:body).returns({
      "errors" => [
        {
          "message" => "GraphQL error message",
          "locations" => [{ "line" => 2, "column" => 11 }],
          "path" => ["theme", "files"],
        },
      ],
      "data" => nil,
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(error_response).once

    # This method doesn't have a rescue block, so we can test for the exception directly
    assert_raises(ShopifyAPI::Errors::InvalidGraphqlRequestError) do
      manager.send(:fetch_json_templates, @mock_client, "theme_id", ["templates/product.json"])
    end
  end

  test "#all_sections_support_app_blocks? raises InvalidGraphqlRequestError when GraphQL errors are present" do
    manager = ShopifyApp::ScriptTagsManager.new(@script_tags, "example-app.com")
    manager.stubs(:graphql_client).returns(@mock_client)

    # Mock GraphQL error response
    error_response = mock
    error_response.stubs(:body).returns({
      "errors" => [
        {
          "message" => "GraphQL error message",
          "locations" => [{ "line" => 2, "column" => 11 }],
          "path" => ["theme", "files"],
        },
      ],
      "data" => nil,
    })

    # Set up the response for the GraphQL client
    @mock_client.expects(:query).returns(error_response).once

    # Stub the rescue block to verify the error is raised before it's caught
    ShopifyApp::Logger.expects(:error).with("Error checking section support: GraphQL error message")

    # The method will return false due to the rescue block
    assert_equal false,
      manager.send(:all_sections_support_app_blocks?, @mock_client, "theme_id", ["sections/main-product.liquid"])
  end

  private

  def mock_empty_script_tags_response
    empty_response = mock
    empty_response.stubs(:body).returns({
      "data" => {
        "scriptTags" => {
          "edges" => [],
        },
      },
    })
    @mock_client.stubs(:query).returns(empty_response)
  end

  def mock_script_tags_response(script_tags)
    edges = script_tags.map { |tag| { "node" => tag } }

    response = mock
    response.stubs(:body).returns({
      "data" => {
        "scriptTags" => {
          "edges" => edges,
        },
      },
    })
    @mock_client.stubs(:query).returns(response)
  end

  def expect_script_tag_creation(src)
    response = mock
    response.stubs(:body).returns({
      "data" => {
        "scriptTagCreate" => {
          "scriptTag" => {
            "id" => "gid://shopify/ScriptTag/#{rand(1000)}",
            "src" => src,
            "displayScope" => "ONLINE_STORE",
            "cache" => true,
          },
          "userErrors" => [],
        },
      },
    })

    @mock_client.expects(:query).with(
      has_entries(
        variables: {
          input: {
            src: src,
            displayScope: "ONLINE_STORE",
            cache: true,
          },
        },
      ),
    ).returns(response)
  end

  def expect_script_tag_deletion(id)
    response = mock
    response.stubs(:body).returns({
      "data" => {
        "scriptTagDelete" => {
          "deletedScriptTagId" => id,
          "userErrors" => [],
        },
      },
    })

    @mock_client.expects(:query).with(
      has_entries(
        variables: { id: id },
      ),
    ).returns(response)
  end
end
