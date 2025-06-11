# frozen_string_literal: true

module ShopifyApp
  module Auth
    class AuthScopes
      attr_reader :scopes

      def initialize(scopes)
        @scopes = case scopes
          when String
            scopes.split(/\s*,\s*/).map(&:strip).reject(&:empty?)
          when Array
            scopes.map(&:to_s).map(&:strip).reject(&:empty?)
          when AuthScopes
            scopes.scopes.dup
          else
            []
        end.uniq
      end

      def to_s
        @scopes.join(",")
      end

      def to_a
        @scopes.dup
      end

      def ==(other)
        case other
        when AuthScopes
          @scopes.sort == other.scopes.sort
        when String, Array
          self == self.class.new(other)
        else
          false
        end
      end

      alias_method :eql?, :==

      def hash
        @scopes.sort.hash
      end

      def <=>(other)
        return nil unless other.is_a?(AuthScopes)
        @scopes.sort <=> other.scopes.sort
      end

      def covers?(other)
        other_scopes = case other
          when AuthScopes
            other.scopes
          when String, Array
            self.class.new(other).scopes
          else
            return false
        end
        
        (other_scopes - @scopes).empty?
      end

      def empty?
        @scopes.empty?
      end

      def include?(scope)
        @scopes.include?(scope.to_s)
      end

      def +(other)
        self.class.new(@scopes + self.class.new(other).scopes)
      end

      def -(other)
        self.class.new(@scopes - self.class.new(other).scopes)
      end

      def as_json(*args)
        { "scopes" => @scopes }
      end

      def to_json(*args)
        as_json.to_json(*args)
      end
    end
  end
end 