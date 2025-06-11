# frozen_string_literal: true

module ShopifyApp
  module Auth
    class AssociatedUser
      attr_reader :id, :first_name, :last_name, :email, :account_owner,
                  :locale, :collaborator, :email_verified

      def initialize(attrs = {})
        @id = attrs["id"]
        @first_name = attrs["first_name"]
        @last_name = attrs["last_name"]
        @email = attrs["email"]
        @account_owner = attrs["account_owner"] || false
        @locale = attrs["locale"]
        @collaborator = attrs["collaborator"] || false
        @email_verified = attrs["email_verified"] || false
      end

      def ==(other)
        return false unless other.is_a?(AssociatedUser)

        id == other.id &&
          first_name == other.first_name &&
          last_name == other.last_name &&
          email == other.email &&
          account_owner == other.account_owner &&
          locale == other.locale &&
          collaborator == other.collaborator &&
          email_verified == other.email_verified
      end

      def to_h
        {
          "id" => id,
          "first_name" => first_name,
          "last_name" => last_name,
          "email" => email,
          "account_owner" => account_owner,
          "locale" => locale,
          "collaborator" => collaborator,
          "email_verified" => email_verified,
        }
      end

      def as_json(*args)
        to_h
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end
  end
end 