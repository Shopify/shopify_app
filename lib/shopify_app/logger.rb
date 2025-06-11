# frozen_string_literal: true

module ShopifyApp
  class Logger
    class << self
      def send_to_logger(method, message = nil, &block)
        # Skip deprecated version check for now
        current_shop = ShopifyApp::SessionContext.active_session&.shop || "Shop Not Found"
        logger = Rails.logger
        log_context = { shop: current_shop }

        if block_given?
          logger.send(method, log_context, &block)
        else
          logger.send(method, "#{log_context} #{message}")
        end
      end

      [:debug, :info, :warn, :error, :fatal, :unknown].each do |method|
        define_method(method) do |message = nil, &block|
          send_to_logger(method, message, &block)
        end
      end

      def valid_version(_version)
        true
      end
    end
  end
end
