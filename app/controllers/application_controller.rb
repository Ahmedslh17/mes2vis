class ApplicationController < ActionController::Base
  private

  # Autorise 1 facture gratuite par compte, ensuite abo obligatoire
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
