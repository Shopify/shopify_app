# frozen_string_literal: true

module ShopifyApp
  module SanitizedParams
    protected

    def sanitized_shop_name
      @sanitized_shop_name ||= sanitize_shop_param(params)
    end

    def referer_sanitized_shop_name
      return unless request.referer.present?

      @referer_sanitized_shop_name ||= begin
        referer_uri = URI(request.referer)
        query_params = Rack::Utils.parse_query(referer_uri.query)

        sanitize_shop_param(query_params.with_indifferent_access)
      end
    end

    def sanitize_shop_param(params)
      return unless params[:shop].present?

      ShopifyApp::Utils.sanitize_shop_domain(params[:shop])
    end

    def sanitized_params
      parameters = request.post? ? request.request_parameters : request.query_parameters
      parameters.clone.tap do |params_copy|
        if params[:shop].is_a?(String)
          params_copy[:shop] = sanitize_shop_param(params)
        end
      end
    end
  end
end
