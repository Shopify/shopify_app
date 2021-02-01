# frozen_string_literal: true
OmniAuth.config.allowed_request_methods = [:post, :get]
# When OmniAuth.config.allowed_request_methods includes :get (as above), OmniAuth will log a :warn level log
# with every GET request. The following configuration line silences the warnings.
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use(OmniAuth::Builder) do
end
