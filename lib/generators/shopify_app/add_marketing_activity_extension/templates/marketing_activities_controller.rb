# frozen_string_literal: true

class MarketingActivitiesController < ShopifyApp::ExtensionVerificationController
  def preload_form_data
    preload_data = {
      "form_data": {},
    }
    render(json: preload_data, status: :ok)
  end

  def update
    render(json: {}, status: :accepted)
  end

  def pause
    render(json: {}, status: :accepted)
  end

  def resume
    render(json: {}, status: :accepted)
  end

  def delete
    render(json: {}, status: :accepted)
  end

  def preview
    placeholder_img = "https://cdn.shopify.com/s/files/1/0533/2089/files/placeholder-images-image_small.png"
    preview_response = {
      "desktop": {
        "preview_url": placeholder_img,
        "content_type": "text/html",
        "width": 360,
        "height": 200,
      },
      "mobile": {
        "preview_url": placeholder_img,
        "content_type": "text/html",
        "width": 360,
        "height": 200,
      },
    }
    render(json: preview_response, status: :ok)
  end

  def create
    render(json: {}, status: :ok)
  end

  def republish
    render(json: {}, status: :accepted)
  end

  def errors
    request_id = params[:request_id]
    message = params[:message]

    ShopifyApp::Logger.info("[Marketing Activity App Error Feedback]"\
      "Request id: #{request_id}, message: #{message}")

    render(json: {}, status: :ok)
  end
end
