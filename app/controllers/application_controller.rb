class ApplicationController < ActionController::Base
  before_action :redirect_unauthenticated_to_login

  # ✅ Redirections Devise : évite retour landing
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_up_path_for(resource)
    # Si confirmable est activé, Devise peut ne pas connecter l'utilisateur.
    # Dans tous les cas, on évite la landing.
    dashboard_path
  end

  private

  # ✅ Empêche d'être renvoyé vers la landing "par défaut"
  # Non connecté -> login (sauf pages publiques + devise)
  def redirect_unauthenticated_to_login
    return if user_signed_in?

    allowed = [
      # Pages publiques
      "pages#home", "pages#legal", "pages#privacy", "pages#support",

      # Devise : login / signup
      "devise/sessions#new", "devise/sessions#create",
      "devise/registrations#new", "devise/registrations#create",

      # Confirmations (ton controller custom)
      "users/confirmations#new", "users/confirmations#create", "users/confirmations#show",

      # Healthcheck
      "rails/health#show"
    ]

    return if allowed.include?("#{controller_path}##{action_name}")

    redirect_to new_user_session_path
  end

  # 🔒 Autorise 1 facture gratuite par compte, ensuite abo obligatoire
  def require_subscription_for_second_invoice!
    return unless user_signed_in?

    # Déjà abonné => OK
    return if current_user.subscribed?

    company = current_user.company
    return if company.nil?

    # 0 facture => encore dans l'essai gratuit => OK
    invoices_count = company.invoices.count
    return if invoices_count < 1

    # Sinon => abo requis
    redirect_to subscription_path, alert: "Tu as utilisé ta facture gratuite. Active ton abonnement pour créer d’autres factures."
  end
end
