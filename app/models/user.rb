class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Relations
  has_one :company, dependent: :destroy

  # === Abonnements Stripe ===

  # Est-ce que l'utilisateur a un abonnement actif ?
  # (on considère aussi "trialing" si un jour tu ajoutes des périodes d’essai)
  def subscribed?
    subscription_status.in?(%w[active trialing])
  end

  # Est-ce qu'il fait partie de l’offre early (200 premiers à vie) ?
  def early_access?
    !!(grandfathered || subscription_plan == "early")
  end
end
