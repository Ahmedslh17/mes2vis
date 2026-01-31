class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company
  before_action :set_client, only: [:show, :edit, :update, :destroy]

  def index
    @clients = @company.clients.order(created_at: :desc)
  end

  def show
    # Toutes les factures liées à ce client
    @invoices = @company.invoices
                        .where(client_id: @client.id)
                        .order(issue_date: :desc)
  end

  def new
    @client = @company.clients.new
  end

  def create
    @client = @company.clients.new(client_params)

    if @client.save
      redirect_to clients_path, notice: "Client créé avec succès."
    else
      # ✅ Pas de flash global : on affiche uniquement le bloc d'erreurs dans la vue
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to client_path(@client), notice: "Client mis à jour avec succès."
    else
      # ✅ Pas de flash global : on affiche uniquement le bloc d'erreurs dans la vue
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: "Client supprimé avec succès."
  end

  private

  def set_company
    @company = current_user.company
  end

  def set_client
    @client = @company.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(
      :name,
      :contact_name,
      :email,
      :phone,
      :address,
      :zip_code,
      :city,
      :country,
      :vat_number,
      :client_type,
      :siren
    )
  end
end
