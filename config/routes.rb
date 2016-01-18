Rails.application.routes.draw do
  root :to => redirect("/accounts")
  resources :accounts, :only => [:index, :show, :new, :create]
  resources :events, :only => [:index, :create]
  get "/new_payment", :to => "events#new_payment"
  post "/new_payment", :to => "events#create_payment"
  get "/new_purchase", :to => "events#new_purchase"
  post "/new_purchase", :to => "events#create_purchase"
end
