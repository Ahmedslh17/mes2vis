Rails.application.routes.draw do
  # Devise (avec controller de confirmations personnalisé)
  devise_for :users, controllers: {
    confirmations: 'users/confirmations'
  }

  # Root selon connexion
authenticated :user do
  root "dashboard#index", as: :authenticated_root
end

unauthenticated do
  root "pages#home", as: :unauthenticated_root
end


  # 🔔 Abonnement / Stripe
  get "/abonnement", to: "subscriptions#show", as: :abonnement

  resource :subscription, only: [:show] do
    post :create_checkout_session   # POST /subscription/create_checkout_session
    get  :billing_portal            # GET  /subscription/billing_portal
  end

  # Factures
  resources :invoices do
    member do
      post  :duplicate
      patch :update_status
      post  :send_email
      post  :send_reminder
    end
  end

  # Paiement d'une facture -> PaymentsController#create
  post "invoices/:id/pay",
       to: "payments#create",
       as: :pay_invoice

  # Clients
  resources :clients

  # Paramètres
  resource :settings, only: [:edit, :update]

  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Footer
  get "mentions-legales", to: "pages#legal",   as: :legal_mentions
  get "confidentialite",  to: "pages#privacy", as: :privacy
  get "support",          to: "pages#support", as: :support

  # Healthcheck Rails
  get "up" => "rails/health#show", as: :rails_health_check
end
