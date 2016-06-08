module ShopifyApp
  module WordMatcher

    def initalizer(invalid, valid)
      @invalid = invalid
      @valid = valid
      calculate_length_of_word(invalid, valid)
    end

  end
end
