require 'response'
##
# classe du contrôleur admin
class AdminController < ApplicationController

  ##
  # demande du mot de passe de l'administrateur
  def password; end

  ##
  # vérification du mot de passe de l'administrateur
  def check_password
    if params[:password].crypt('ld') == 'ldrGUIh/JewKE'
      session[:admin] = true
      redirect_to root_url, notice: 'Vous êtes administrateur'
    else
      flash.now[:alert] = 'Erreur de saisie'
      render :password
    end
  end
end
