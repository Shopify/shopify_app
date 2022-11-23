# frozen_string_literal: true

class ActionController::TestCase
  def assert_client_side_redirect(expected_redirect_url)
    assert_equal expected_redirect_url, actual_client_side_redirect_url
  end

  private

  def expected_redirect_url
    login_url = URI(ShopifyApp.configuration.login_url)
    login_url.query = URI.encode_www_form(
      shop: @shopify_domain,
      host: @host,
      return_to: request.fullpath,
      reauthorize: 1,
    )
    login_url.to_s
  end

  def actual_client_side_redirect_url
    data_target = Nokogiri::HTML(response.body).at("body div#redirection-target").attr("data-target")
    JSON.parse(data_target)["url"]
  end
end
