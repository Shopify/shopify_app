Rails.application.routes.draw do
  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'auth/shopify/callback' => :callback
    get 'logout' => :destroy, :as => :logout
  end

  get 'modal' => "home#modal", :as => :modal
  get 'modal_buttons' => "home#modal_buttons", :as => :modal_buttons
  get 'regular_app_page' => "home#regular_app_page"
  get 'help' => "home#help"
  get 'pagination' => "home#pagination"
  get 'breadcrumbs' => "home#breadcrumbs"
  get 'buttons' => "home#buttons"
  get 'form_page' => "home#form_page"
  post 'form_page' => "home#form_page"
  get 'error' => 'home#error'

  root :to => 'home#index'
end
