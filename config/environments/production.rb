require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # config.require_master_key = true

  # config.public_file_server.enabled = false

  # config.assets.css_compressor = :sass
  config.assets.compile = false

  # config.asset_host = "http://assets.example.com"

  # config.action_dispatch.x_sendfile_header = "X-Sendfile"
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL
  config.force_ssl = true

  # ===============================
  # ✅ IMPORTANT: URLS EN PROD (Stripe, mails, etc.)
  # ===============================
  config.action_controller.default_url_options = {
    host: "mes2vis.com",
    protocol: "https"
  }

  Rails.application.routes.default_url_options = {
    host: "mes2vis.com",
    protocol: "https"
  }

  config.action_mailer.default_url_options = {
    host: "mes2vis.com",
    protocol: "https"
  }

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # config.cache_store = :mem_cache_store
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "mes2vis_production"

  # ===============================
  # 📧 MAILER (HOSTINGER EMAIL)
  # ===============================
  config.action_mailer.default_options = {
    from: "Mes2Vis <notifications@mes2vis.com>"
  }

  config.action_mailer.perform_caching = false

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.hostinger.com",
    port:                 587,
    user_name:            ENV["SMTP_USERNAME"],
    password:             ENV["SMTP_PASSWORD"],
    authentication:       :plain,
    enable_starttls_auto: true
  }

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "mes2vis.com",
  #   /.*\.mes2vis\.com/
  # ]
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
