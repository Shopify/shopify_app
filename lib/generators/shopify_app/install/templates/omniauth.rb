# frozen_string_literal: true
# When OmniAuth.config.allowed_request_methods includes :get (as above), OmniAuth will log a :warn level log
# with every GET request. The following configuration line silences the warnings.

Rails.application.config.middleware.use(OmniAuth::Builder) do
end
