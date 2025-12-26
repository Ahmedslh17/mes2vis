class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

    @stripe_public_key = ENV["STRIPE_PUBLIC_KEY"]
    @early_price_id    = ENV["STRIPE_PRICE_ID_EARLY"]
    @standard_price_id = ENV["STRIPE_PRICE_ID_STANDARD"]

    @early_count = User.where(subscription_plan: "early").count
    @can_early   = @early_count < 200

    if params[:session_id].present?
      update_subscription_from_checkout(params[:session_id])
      flash.now[:notice] = "Ton abonnement a bien été activé ✅"
    end
  rescue => e
    Rails.logger.error("Erreur SubscriptionsController#show : #{e.message}")
    flash.now[:alert] = "Impossible de récupérer les informations d’abonnement pour le moment."
  end

  def create_checkout_session
    plan = params[:plan] == "early" ? "early" : "standard"

    price_id =
      if plan == "early"
        ENV["STRIPE_PRICE_ID_EARLY"]
      else
        ENV["STRIPE_PRICE_ID_STANDARD"]
      end

    unless price_id.present?
      redirect_to subscription_path, alert: "Configuration Stripe manquante (ID de prix)."
      return
    end

    if plan == "early"
      early_count = User.where(subscription_plan: "early").count
      if early_count >= 200
        redirect_to subscription_path, alert: "L’offre early est complète. Il ne reste plus que l’abonnement standard."
        return
      end
    end

    customer_id = ensure_stripe_customer_id!(current_user)

    session = Stripe::Checkout::Session.create(
      mode: "subscription",
      payment_method_types: ["card"],
      customer: customer_id,
      line_items: [
        { price: price_id, quantity: 1 }
      ],
      allow_promotion_codes: true,
      subscription_data: {
        metadata: {
          user_id: current_user.id,
          plan: plan
        }
      },
      metadata: {
        user_id: current_user.id,
        plan: plan
      },
      success_url: "#{subscription_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url:  subscription_url
    )

    redirect_to session.url, allow_other_host: true
  rescue => e
    Rails.logger.error("Erreur Stripe Checkout : #{e.message}")
    redirect_to subscription_path, alert: "Impossible de créer la session de paiement pour le moment."
  end

  def billing_portal
    unless current_user.stripe_customer_id.present?
      redirect_to subscription_path, alert: "Aucun abonnement Stripe associé à ce compte."
      return
    end

    session = Stripe::BillingPortal::Session.create(
      customer: current_user.stripe_customer_id,
      return_url: subscription_url
    )

    redirect_to session.url, allow_other_host: true
  rescue => e
    Rails.logger.error("Erreur Stripe Billing Portal : #{e.message}")
    redirect_to subscription_path, alert: "Impossible d’ouvrir le portail de gestion de l’abonnement."
  end

  private

  def ensure_stripe_customer_id!(user)
    return user.stripe_customer_id if user.stripe_customer_id.present?

    customer = Stripe::Customer.create(email: user.email)
    user.update!(stripe_customer_id: customer.id)

    customer.id
  end

  def update_subscription_from_checkout(session_id)
  session      = Stripe::Checkout::Session.retrieve(session_id)
  subscription = Stripe::Subscription.retrieve(session.subscription)

  plan     = subscription.metadata["plan"] || session.metadata["plan"]
  plan   ||= "standard"

  # ✅ Robust fallback for current_period_end depending on Stripe API shape
  period_end =
    if subscription.respond_to?(:current_period_end) && subscription.current_period_end.present?
      subscription.current_period_end
    else
      item = subscription.items&.data&.first
      item&.current_period_end
    end

  current_user.update!(
    stripe_customer_id:              session.customer,
    stripe_subscription_id:          subscription.id,
    subscription_status:             subscription.status,
    subscription_plan:               plan,
    subscription_current_period_end: (period_end.present? ? Time.at(period_end) : nil),
    grandfathered:                   (plan == "early")
  )
end
end
