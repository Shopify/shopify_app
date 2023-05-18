# typed: true
# frozen_string_literal: true

module TestHelpers
  class FakeSessionStorage
    extend T::Sig

    sig { returns(T::Hash[String, ShopifyAPI::Auth::Session]) }
    attr_reader :sessions

    sig { returns(T.nilable(T::Boolean)) }
    attr_reader :error_on_save, :error_on_delete

    sig do
      params(
        sessions: T.nilable(T::Hash[String, ShopifyAPI::Auth::Session]),
        error_on_save: T.nilable(T::Boolean),
        error_on_delete: T.nilable(T::Boolean),
      ).void
    end
    def initialize(sessions: {}, error_on_save: false, error_on_delete: false)
      @sessions = T.must(sessions)
      @error_on_save = error_on_save
      @error_on_delete = error_on_delete
    end

    sig do
      override.params(session: ShopifyAPI::Auth::Session)
        .returns(T::Boolean)
    end
    def store_session(session)
      return false if error_on_save

      sessions[session.id] = session
      true
    end

    sig do
      override.params(id: String)
        .returns(T.nilable(ShopifyAPI::Auth::Session))
    end
    def load_session(id)
      sessions[id]
    end

    sig do
      override.params(id: String)
        .returns(T::Boolean)
    end
    def delete_session(id)
      return false if error_on_delete

      sessions.delete(id)
      true
    end
  end
end
