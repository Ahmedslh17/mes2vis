require_relative "boot"
begin
  require "dotenv/load"
rescue LoadError
  # dotenv n'est pas installé en production (normal)
end

require "rails/all"

Bundler.require(*Rails.groups)

module Mes2vis
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    # i18n
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [:fr, :en]

    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
