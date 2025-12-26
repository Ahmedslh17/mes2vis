require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Reload du code à chaque requête (pratique en dev)
  config.enable_reloading = true

  # Pas de eager load en dev
  config.eager_load = false

  # Afficher les pages d’erreur complètes
  config.consider_all_requests_local = true

  # Server-Timing
  config.server_timing = true

  # Pas de cache en dev
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Active Storage en local
  config.active_storage.service = :local

  # Mailer cache
  config.action_mailer.perform_caching = false

  # Dépréciations
  config.active_support.deprecation = :log

  # Erreur si migrations en attente
  config.active_record.migration_error = :page_load

  # Logs plus verbeux
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true

  # Moins de bruit sur les assets
  config.assets.quiet = true

  config.action_controller.raise_on_missing_callback_actions = true

  # ======================================
  # 📧 CONFIGURATION SMTP HOSTINGER
  # ======================================
  # URL utilisée dans les liens d’email (confirmation, reset, etc.)
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Envoi des emails via SMTP Hostinger
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.hostinger.com",
    port:                 587,
    user_name:            ENV["SMTP_USERNAME"],   # => "notifications@mes2vis.com"
    password:             ENV["SMTP_PASSWORD"],   # => mot de passe de cette boîte mail
    authentication:       :plain,
    enable_starttls_auto: true
  }

  # On veut vraiment envoyer les mails en dev
  config.action_mailer.perform_deliveries = true
  # Et voir les erreurs si ça échoue
  config.action_mailer.raise_delivery_errors = true

  # ✅ IMPORTANT : URL helpers en dev (subscription_url, etc.)
  Rails.application.routes.default_url_options = {
    host: "localhost",
    port: 3000,
    protocol: "http"
  }
end
