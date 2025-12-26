Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

if Stripe.api_key.blank?
  Rails.logger.warn("[Stripe] STRIPE_SECRET_KEY manquante")
end
