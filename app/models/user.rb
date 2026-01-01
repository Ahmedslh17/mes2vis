class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Relations
  has_one :company, dependent: :destroy

  # =========================
  # 🔐 Mot de passe sécurisé
  # =========================
  PASSWORD_REGEX = /\A(?=.{8,})(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).*\z/

  validate :password_complexity, if: -> { password.present? }

  def password_complexity
    return if password.match?(PASSWORD_REGEX)

    errors.add :password, "doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial"
  end

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
