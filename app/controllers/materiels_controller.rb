##
# classe du contrôleur des matériels
class MaterielsController < ApplicationController
  before_action :set_materiel, only: %i[show edit update destroy]
  before_action :test_admin, only: %i[edit update destroy new create]
  before_action :set_menu

  # GET /materiels
  def index
    @materiels = Materiel.all.order(reforme: :asc, poids: :desc)
    @affiche_poids = false
  end

  # GET  /materiels/traces/1
  def index_trace
    @materiels = Trace.find(params[:id]).materiels.order(poids: :desc)
    @affiche_poids = true
    render 'index'
  end

  # GET /materiels/1
  def show; end

  # GET /materiels/new
  def new
    @materiel = Materiel.new
    @materiel.photo = '0pasdimage.jpg'
    @photos_candidates = photos_candidates
  end

  # GET /materiels/1/edit
  def edit
    @photos_candidates = photos_candidates
  end

  # POST /materiels
  def create
    @materiel = Materiel.new(materiel_params)
    photo = charge_photo_si_besoin
    @materiel.photo = photo unless photo.nil?
    if @materiel.save
      redirect_to @materiel, notice: 'Le matériel est bien enregistré'
    else
      @photos_candidates = photos_candidates
      render :new
    end
  end

  # PATCH/PUT /materiels/1
  def update
    photo = charge_photo_si_besoin
    params[:materiel][:photo] = photo unless photo.nil?
    if @materiel.update(materiel_params)
      redirect_to @materiel, notice: 'Le matériel a bien été corrigé.'
    else
      @photos_candidates = photos_candidates
      render :edit
    end
  end

  # DELETE /materiels/1
  def destroy
    @materiel.destroy
    redirect_to materiels_url, notice: 'Le matériel a bien été détruit.'
  end

  private

  # dresse la liste des photos candidats pour un matériel.
  # elle comprend les photos du répertoire matériels qui ne
  # sont pas encore assignées à un matériel
  def photos_candidates
    repertoire = Rails.root.join('public', 'materiels')
    photos_repertoire = Dir.entries(repertoire)
                           .reject do |f|
                             File.directory? File.join(repertoire, f)
                           end
    photos_base = Materiel.where.not(photo: '0pasdimage.jpg', id: @materiel.id)
                          .select(:photo)
                          .distinct
                          .collect(&:photo)
    (photos_repertoire - photos_base).sort.collect { |p| [p, p] }
  end

  # définit le matériel utilisé
  def set_materiel
    @materiel = Materiel.find(params[:id])
  end

  # réduit la liste des paramètres acceptés
  def materiel_params
    params.require(:materiel).permit(:nom, :description, :photo, :poids, :reforme)
  end

  # définit l'option du menu à mettre en évidence
  def set_menu
    session[:menu] = 'Matériels'
  end

  # redirige les tentatives de modification par un non administrateur
  def test_admin
    return if session[:admin]
    if %w[destroy edit update].index(action_name)
      redirect_to @materiel, notice: "Vous n'êtes pas administrateur"
    else
      redirect_to materiels_url, notice: "Vous n'êtes pas administrateur"
    end
  end

  # charge la photo sélectionnée par l'utilisateur sur son pdt
  def charge_photo_si_besoin
    uploaded_io = params[:materiel][:nouvelle_photo]
    if uploaded_io.nil?
      nil
    else
      File.open(Rails.root.join('public', 'materiels',
                                uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      uploaded_io.original_filename
    end
  end
end
