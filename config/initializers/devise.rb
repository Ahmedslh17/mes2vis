Devise.setup do |config|

  # Adresse expéditeur pour TOUS les mails Devise (confirmation, reset, etc.)
  config.mailer_sender = 'Mes2Vis <notifications@mes2vis.com>'
   require 'devise/orm/active_record'

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]

  config.stretches = Rails.env.test? ? 1 : 12

  # ===== CONFIRMABLE =====
  # L’utilisateur doit confirmer son compte avant connexion
  config.allow_unconfirmed_access_for = 0.days

  # Pas de délai d'expiration du lien de confirmation
  # (tu peux mettre 3.days si tu veux plus tard)
  # config.confirm_within = 3.days

  # On désactive la reconfirmation pour éviter des blocages inutiles
  config.reconfirmable = false

  # =======================

  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.expire_all_remember_me_on_sign_out = true

  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
