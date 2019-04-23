##
# classe du contrôleur de l'application
# elle comprend les fonctions non liées à un model
# qui ne relèvent pas de l'administrateur
class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }

  ##
  # affichage de la page d'accueil
  def index
    session[:menu] = "Home"
    @date_du_jour = Date.today
    @ma_date_du_jour = Madate.new(@date_du_jour.day, @date_du_jour.month, @date_du_jour.year)
    @ecart_retraite = @ma_date_du_jour.ecart(1, 7, 2018)
    @ecart_depart = @ma_date_du_jour.ecart(11, 5, 2019)
  end

  ##
  # affichage de l'agenda Google
  def agenda
    session[:menu] = 'Dans les jours qui viennent'
    @agenda = File.read(File.join('public','agenda.txt'))
  end

  def agenda_edit
    @agenda = File.read(File.join('public','agenda.txt'))
  end

  def agenda_update
    @agenda = params[:agenda]
    File.write(File.join('public', 'agenda.txt'), @agenda)
    redirect_to agenda_path, notice: "L'agenda a bien été modifié"
  end

  ##
  # chargement d'une image par Tinymce
  def upload_image
    uploaded_io = params[:file]
    statut = :ok
    if uploaded_io.nil?
      json_f = {}
    else
      json_f = { location: File.join('..', 'images',
                                     uploaded_io.original_filename) }
      begin
        File.open(Rails.root
                      .join('public', 'images',
                            uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
      rescue IOError
        statut = :internal_server_error
      end
    end
    render json: json_f, status: statut
  end
end