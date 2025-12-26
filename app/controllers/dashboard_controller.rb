class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "application"

  def index
    return redirect_to unauthenticated_root_path unless current_user

    unless current_user.confirmed?
      sign_out(current_user)
      flash[:alert] = "Veuillez confirmer votre email avant d'accéder au dashboard."
      return redirect_to new_user_session_path
    end

    @company = current_user.company || current_user.create_company!(
      name: "Entreprise de #{current_user.email}",
      address: "Adresse non renseignée",
      zip_code: "00000",
      city: "Ville inconnue",
      country: "France"
    )

    invoices = @company.invoices

    @total_invoices_count   = invoices.count
    @paid_invoices_count    = invoices.where(status: "paid").count
    @pending_invoices_count = invoices.where(status: "pending").count
    @overdue_invoices_count = invoices.where(status: "overdue").count

    @total_amount_cents = invoices.sum(:total_cents)

    current_month_range = Date.current.beginning_of_month..Date.current.end_of_month
    @month_amount_cents = invoices.where(issue_date: current_month_range).sum(:total_cents)

    build_monthly_revenue(invoices)
    @latest_invoices = invoices.includes(:client).order(issue_date: :desc).limit(5)
  end

  private

  def build_monthly_revenue(invoices)
    start_month = 5.months.ago.beginning_of_month
    @revenue_labels = []
    @revenue_amounts_cents = []

    6.times do |i|
      month = start_month + i.months
      month_range = month..month.end_of_month

      total_cents = invoices.where(issue_date: month_range).sum(:total_cents)
      @revenue_labels << month.strftime("%b %Y")
      @revenue_amounts_cents << total_cents
    end
  end
end
