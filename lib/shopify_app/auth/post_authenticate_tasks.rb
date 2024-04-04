# frozen_string_literal: true

module ShopifyApp
  module Auth
    class PostAuthenticateTasks
      class << self
        def perform(session)
          ShopifyApp::Logger.debug("Performing post authenticate tasks")
          # Ensure we use the shop session to install webhooks
          session_for_shop = session.online? ? shop_session(session) : session

          install_webhooks(session_for_shop)

          perform_after_authenticate_job(session)
        end

        private

        def shop_session(session)
          ShopifyApp::SessionRepository.retrieve_shop_session_by_shopify_domain(session.shop)
        end

        def install_webhooks(session)
          ShopifyApp::Logger.debug("PostAuthenticateTasks: Installing webhooks")
          return unless ShopifyApp.configuration.has_webhooks?

          WebhooksManager.queue(session.shop, session.access_token)
        end

        def perform_after_authenticate_job(session)
          ShopifyApp::Logger.debug("PostAuthenticateTasks: Performing after_authenticate_job")
          config = ShopifyApp.configuration.after_authenticate_job

          return unless config && config[:job].present?

          job = config[:job]
          job = job.constantize if job.is_a?(String)

          if config[:inline] == true
            job.perform_now(shop_domain: session.shop)
          else
            job.perform_later(shop_domain: session.shop)
          end
        end
      end
    end
  end
end
