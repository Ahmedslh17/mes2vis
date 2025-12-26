class Users::ConfirmationsController < Devise::ConfirmationsController
  protected

  # Redirection après confirmation de l'email
  def after_confirmation_path_for(resource_name, resource)
    dashboard_path
  end
end
