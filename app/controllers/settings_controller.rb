class SettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
    @company = current_user.company
  end

  def update
    @company = current_user.company

    if @company.update(company_params)
      redirect_to edit_settings_path, notice: "Profil entreprise mis à jour avec succès."
    else
      flash.now[:alert] = "Erreur lors de la mise à jour du profil entreprise."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def company_params
  params.require(:company).permit(
    :name,
    :legal_name,
    :address,
    :zip_code,
    :city,
    :country,
    :phone,
    :website,
    :email,
    :siren,
    :vat_number,
    :iban,
    :bic,
    :payment_instructions,
    :logo,         # 👈 upload du logo
    :remove_logo   # 👈 checkbox pour le supprimer
  )
end

end
