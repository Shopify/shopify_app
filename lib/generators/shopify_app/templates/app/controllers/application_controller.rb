class ApplicationController < ActionController::Base
  protect_from_forgery
  
  # Ask shop to authorize app again if additional permissions are required
  # rescue_from ActiveResource::ForbiddenAccess do
  #   session[:shopify] = nil
  #   flash[:notice] = "This app requires additional permissions, please log in and authorize it."
  #   redirect_to controller: :sessions, action: :create
  # end
end
