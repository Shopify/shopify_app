# frozen_string_literal: true

module ShopifyApp
  class ScriptTagsManager
    def self.queue(shop_domain, shop_token, script_tags)
      ShopifyApp::ScriptTagsManagerJob.perform_later(
        shop_domain: shop_domain,
        shop_token: shop_token,
        # Procs cannot be serialized so we interpolate now, if necessary
        script_tags: build_src(script_tags, shop_domain),
      )
    end

    def self.build_src(script_tags, domain)
      script_tags.map do |tag|
        next tag unless tag[:src].respond_to?(:call)

        tag = tag.dup
        tag[:src] = tag[:src].call(domain)
        tag
      end
    end

    attr_reader :required_script_tags, :shop_domain

    def initialize(script_tags, shop_domain)
      @required_script_tags = script_tags
      @shop_domain = shop_domain
      @session = nil
    end

    def recreate_script_tags!(session:)
      destroy_script_tags(session: session)
      create_script_tags(session: session)
    end

    def create_script_tags(session:)
      @session = session
      return unless required_script_tags.present?

      template_types_to_check = required_script_tags.flat_map { |tag| tag[:template_types] }.compact.uniq

      if template_types_to_check.any?
        active_theme = fetch_active_theme
        unless active_theme
          ShopifyApp::Logger.debug("Failed to fetch active theme. Skipping script tag creation.")
          return
        end

        if all_templates_support_app_blocks?(active_theme["id"], template_types_to_check)
          ShopifyApp::Logger.info(
            "Theme supports app blocks for templates: #{template_types_to_check.join(", ")}. " \
              "Skipping script tag creation.",
          )
          return
        end
      end

      expanded_script_tags.each do |script_tag|
        create_script_tag(script_tag) unless script_tag_exists?(script_tag[:src])
      end
    end

    def destroy_script_tags(session:)
      @session = session
      script_tags = expanded_script_tags
      fetch_all_script_tags.each do |tag|
        delete_script_tag(tag) if required_script_tag?(script_tags, tag)
      end

      @current_script_tags = nil
    end

    private

    FILES_QUERY = <<~QUERY
      query getFiles($themeId: ID!, $filenames: [String!]!) {
        theme(id: $themeId) {
          files(filenames: $filenames) {
            nodes {
              filename
              body {
                ... on OnlineStoreThemeFileBodyText {
                  content
                }
              }
            }
          }
        }
      }
    QUERY

    ACTIVE_THEME_QUERY = <<~QUERY
      {
        themes(first: 1, roles: [MAIN]) {
          nodes {
            id
            name
          }
        }
      }
    QUERY

    SCRIPT_TAG_CREATE_MUTATION = <<~QUERY
      mutation ScriptTagCreate($input: ScriptTagInput!) {
        scriptTagCreate(input: $input) {
          scriptTag {
            id
            src
            displayScope
            cache
          }
          userErrors {
            field
            message
          }
        }
      }
    QUERY

    SCRIPT_TAG_DELETE_MUTATION = <<~QUERY
      mutation scriptTagDelete($id: ID!) {
        scriptTagDelete(id: $id) {
          deletedScriptTagId
          userErrors {
            field
            message
          }
        }
      }
    QUERY

    SCRIPT_TAGS_QUERY = <<~QUERY
      {
        scriptTags(first: 250) {
          edges {
            node {
              id
              src
              displayScope
              cache
            }
          }
        }
      }
    QUERY

    def fetch_active_theme
      client = graphql_client

      response = client.query(query: ACTIVE_THEME_QUERY)

      if response.body["errors"].present?
        error_message = response.body["errors"].map { |e| e["message"] }.join(", ")
        raise ShopifyAPI::Errors::InvalidGraphqlRequestError, error_message
      end

      themes = response.body["data"]["themes"]["nodes"]
      return if themes.empty?

      themes.first
    rescue => e
      ShopifyApp::Logger.warn("Failed to fetch active theme: #{e.message}")
      nil
    end

    def all_templates_support_app_blocks?(theme_id, template_types)
      client = graphql_client

      template_filenames = template_types.map { |type| "templates/#{type}.json" }
      json_templates = fetch_json_templates(client, theme_id, template_filenames)

      return false if json_templates.length != template_types.length

      main_sections = extract_main_sections(json_templates)

      return false if main_sections.length != template_types.length

      all_sections_support_app_blocks?(client, theme_id, main_sections)
    rescue => e
      ShopifyApp::Logger.error("Error checking template support: #{e.message}")
      false
    end

    def fetch_json_templates(client, theme_id, template_filenames)
      files_variables = {
        themeId: theme_id,
        filenames: template_filenames,
      }

      files_response = client.query(query: FILES_QUERY, variables: files_variables)

      if files_response.body["errors"].present?
        error_message = files_response.body["errors"].map { |e| e["message"] }.join(", ")
        raise ShopifyAPI::Errors::InvalidGraphqlRequestError, error_message
      end

      files_response.body["data"]["theme"]["files"]["nodes"]
    end

    def extract_main_sections(json_templates)
      main_sections = []

      json_templates.each do |template|
        template_content = template["body"]["content"]
        template_data = JSON.parse(template_content)

        main_section = nil
        template_data["sections"].each do |id, section|
          if id == "main" || section["type"].to_s.start_with?("main-")
            main_section = "sections/#{section["type"]}.liquid"
            break
          end
        end

        main_sections << main_section if main_section
      rescue => e
        ShopifyApp::Logger.error("Error extracting main section from template #{template["filename"]}: #{e.message}")
      end

      main_sections
    end

    def all_sections_support_app_blocks?(client, theme_id, section_filenames)
      return false if section_filenames.empty?

      section_variables = {
        themeId: theme_id,
        filenames: section_filenames,
      }

      section_response = client.query(query: FILES_QUERY, variables: section_variables)

      if section_response.body["errors"].present?
        error_message = section_response.body["errors"].map { |e| e["message"] }.join(", ")
        raise ShopifyAPI::Errors::InvalidGraphqlRequestError, error_message
      end

      section_files = section_response.body["data"]["theme"]["files"]["nodes"]

      return false if section_files.length != section_filenames.length

      # Check if all sections support app blocks
      section_files.all? do |file|
        section_content = file["body"]["content"]
        schema_match = section_content.match(/\{\%\s+schema\s+\%\}([\s\S]*?)\{\%\s+endschema\s+\%\}/m)
        next false unless schema_match

        schema = JSON.parse(schema_match[1])
        schema["blocks"]&.any? { |block| block["type"] == "@app" } || false
      end
    rescue => e
      ShopifyApp::Logger.error("Error checking section support: #{e.message}")
      false
    end

    def expanded_script_tags
      self.class.build_src(required_script_tags, shop_domain)
    end

    def required_script_tag?(script_tags, tag)
      script_tags.map { |w| w[:src] }.include?(tag["src"])
    end

    def create_script_tag(attributes)
      client = graphql_client

      variables = {
        input: {
          src: attributes[:src],
          displayScope: "ONLINE_STORE",
          cache: attributes[:cache] || false,
        },
      }

      response = client.query(query: SCRIPT_TAG_CREATE_MUTATION, variables: variables)

      if response.body["errors"].present?
        error_messages = response.body["errors"].map { |e| e["message"] }.join(", ")
        raise ::ShopifyApp::CreationFailed, "ScriptTag creation failed: #{error_messages}"
      end

      if response.body["data"]["scriptTagCreate"]["userErrors"].any?
        errors = response.body["data"]["scriptTagCreate"]["userErrors"]
        error_messages = errors.map { |e| "#{e["field"]}: #{e["message"]}" }.join(", ")
        raise ::ShopifyApp::CreationFailed, "ScriptTag creation failed: #{error_messages}"
      end

      response.body["data"]["scriptTagCreate"]["scriptTag"]
    rescue ShopifyAPI::Errors::HttpResponseError => e
      raise ::ShopifyApp::CreationFailed, e.message
    end

    def delete_script_tag(tag)
      client = graphql_client

      variables = { id: tag["id"] }

      response = client.query(query: SCRIPT_TAG_DELETE_MUTATION, variables: variables)

      if response.body["errors"].present?
        error_messages = response.body["errors"].map { |e| e["message"] }.join(", ")
        ShopifyApp::Logger.error("Failed to delete script tag: #{error_messages}")
        return
      end

      if response.body["data"]["scriptTagDelete"]["userErrors"].any?
        errors = response.body["data"]["scriptTagDelete"]["userErrors"]
        error_messages = errors.map { |e| "#{e["field"]}: #{e["message"]}" }.join(", ")
        ShopifyApp::Logger.error("Failed to delete script tag: #{error_messages}")
        return
      end

      response.body["data"]["scriptTagDelete"]["deletedScriptTagId"]
    rescue ShopifyAPI::Errors::HttpResponseError => e
      ShopifyApp::Logger.error("Failed to delete script tag: #{e.message}")
    end

    def script_tag_exists?(src)
      current_script_tags[src]
    end

    def current_script_tags
      @current_script_tags ||= fetch_all_script_tags.index_by { |tag| tag["src"] }
    end

    def fetch_all_script_tags
      client = graphql_client

      response = client.query(query: SCRIPT_TAGS_QUERY)

      if response.body["errors"].present?
        error_messages = response.body["errors"].map { |e| e["message"] }.join(", ")
        ShopifyApp::Logger.warn("GraphQL error fetching script tags: #{error_messages}")
        return []
      end

      response.body["data"]["scriptTags"]["edges"].map { |edge| edge["node"] }
    rescue => e
      ShopifyApp::Logger.warn("Error fetching script tags: #{e.message}")
      []
    end

    def graphql_client
      ShopifyAPI::Clients::Graphql::Admin.new(session: @session)
    end
  end
end
