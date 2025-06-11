# frozen_string_literal: true

module ShopifyApp
  module Auth
    class AuthScopes
      attr_reader :scopes

      def initialize(scopes)
        @scopes = parse_scopes(scopes).uniq
      end

      def to_s
        @scopes.join(",")
      end

      def to_a
        @scopes.dup
      end

      def covers?(other)
        other_scopes = self.class.new(other).scopes
        (other_scopes - @scopes).empty?
      end

      def ==(other)
        self.class.new(other).scopes.sort == @scopes.sort
      end

      private

      def parse_scopes(scopes)
        case scopes
        when String
          scopes.split(/\s*,\s*/).map(&:strip).reject(&:empty?)
        when Array
          scopes.map(&:to_s).map(&:strip).reject(&:empty?)
        when AuthScopes
          scopes.scopes.dup
        else
          []
        end
      end
    end
  end
end
