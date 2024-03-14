# typed: false
# frozen_string_literal: true

module ShopifyApp
  module WithIdTokenConcern
    extend ActiveSupport::Concern

    def id_token
      @id_token ||= id_token_header || id_token_param
    end

    def id_token_header
      request.headers["HTTP_AUTHORIZATION"]&.match(/^Bearer (.+)$/)&.[](1)
    end

    def id_token_param
      params["id_token"]
    end
  end
end
