# app/controllers/users/confirmations_controller.rb
class Users::ConfirmationsController < Devise::ConfirmationsController
  # On ne touche pas à #show : on garde le comportement Devise par défaut
  # (confirmation du compte à partir du token dans l'URL)

  protected

  # Après confirmation du compte, où on envoie l'utilisateur ?
  def after_confirmation_path_for(resource_name, resource)
    # On connecte l'utilisateur automatiquement
    sign_in(resource)
    # Puis on le redirige vers le dashboard
    dashboard_path
  end
end
