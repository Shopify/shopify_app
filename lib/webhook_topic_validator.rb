require 'active_support/concern'
module ShopifyApp
  module WebhookTopicValidator
    extend ActiveSupport::Concern

    class InvalidTopic < StandardError; end

    DISTANCES = []

        def calculate_length_of_word(invalid, valid)
          invalid_length, valid_length = invalid.length, valid.length
          return invalid_length if valid_length == 0
          return valid_length if invalid_length == 0
          create_distance_matrix(invalid_length, valid_length, invalid, valid)
        end

        def create_distance_matrix(invalid_length, valid_length, invalid, valid)
          distance = Array.new(invalid_length+1) {Array.new(valid_length+1)}
          calculate_closest_match(invalid_length, valid_length, invalid, valid, distance)
        end

        def calculate_closest_match(invalid_length, valid_length, invalid, valid, distance)
          (0..invalid_length).each {|i| distance[i][0] = i}
          (0..valid_length).each {|j| distance[0][j] = j}
          (1..valid_length).each do |j|
            (1..invalid_length).each do |i|
              distance[i][j] = if invalid[i-1] == valid[j-1]  # adjust index into string
                          distance[i-1][j-1]       # no operation required
                        else
                          [ distance[i-1][j]+1,    # deletion
                            distance[i][j-1]+1,    # insertion
                            distance[i-1][j-1]+1,  # substitution
                          ].min
                        end
            end
          end
          distance = distance[invalid_length][valid_length]
          form_array_of_distances(invalid, valid, distance)
        end

        def form_array_of_distances(invalid, valid, distance)
          DISTANCES << [valid, distance]
          choose_closest_match(invalid)
        end

        @valid = nil

        def choose_closest_match(invalid)
          low_number = 100
          DISTANCES.each do |choose|
            if choose[1] <  low_number
              low_number = choose[1]
              @valid = choose[0]
            end
          end
        end

    VALID_WEBHOOK_TOPICS = ['app/uninstalled',
                            'carts/create',
                            'carts/update',
                            'checkouts/create',
                            'checkouts/delete',
                            'checkouts/update',
                            'collections/create',
                            'collections/delete',
                            'collections/update',
                            'customer_groups/create',
                            'customer_groups/delete',
                            'customer_groups/update',
                            'customers/create',
                            'customers/delete',
                            'customers/disable',
                            'customers/enable',
                            'customers/update',
                            'disputes/create',
                            'disputes/update',
                            'fulfillment_events/create',
                            'fulfillment_events/delete',
                            'fulfillments/create',
                            'fulfillments/update',
                            'order_transactions/create',
                            'orders/cancelled',
                            'orders/create',
                            'orders/delete',
                            'orders/fulfilled',
                            'orders/paid',
                            'orders/partially_fulfilled',
                            'orders/updated',
                            'products/create',
                            'products/delete',
                            'products/update',
                            'refunds/create',
                            'shop/update',
                            'themes/publish'
                        ]
    def is_valid_topic?(options = {})
      @topic = options
      unless VALID_WEBHOOK_TOPICS.any? { |valid| valid == @topic }
        VALID_WEBHOOK_TOPICS.each do |valid|
          calculate_length_of_word(@topic, valid)
        end
        raise InvalidTopic
      end
    end
  end
end
