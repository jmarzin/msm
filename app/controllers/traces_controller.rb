class TracesController < ApplicationController
  TAILLE_PAGE = 12

  # GET /traces
  def index
    return if (@page_a_afficher = corrige_page? do
      Trace.where('type = ? AND titre != ?', controller_name.classify,
                                             'Le projet')
           .order(heure_debut: :desc)
    end).nil?
    @traces = @traces.to_a.slice((@page_a_afficher - 1) *
                                 TAILLE_PAGE, TAILLE_PAGE)
  end

  # GET /traces/1
  def show

    @photos = []
    unless @trace.repertoire_photos.blank?
      repertoire = Rails.root.join('public', 'images', @trace.repertoire_photos)
      @photos = Dir.entries(repertoire) if repertoire.exist?
      @photos = @photos.sort
                       .select { |f| File.extname(f).casecmp('.JPG').zero? || File.extname(f).casecmp('.MP4').zero?}
                       .map { |f| File.join('/images', @trace.repertoire_photos, f) }
    end
    @profils = []
    JSON.parse(@trace.polylines).each do |p|
      texte = ''
      p.each do |t|
        texte += t[0].to_s + ',' + t[1].to_s + ' '
      end
      @profils << texte
    end
  end

  # GET /traces/new
  def new
    @trace = Trace.new(type: controller_name.classify)
    init_variables
    @garder_points = false # il n'y en a pas encore
  end

  # POST /traces
  def create
    unless params[@class_symbol][:points_attributes].nil?
      params[@class_symbol][:points_attributes].each do |_cle, pa|
        @trace.points << Point.new(distance: pa[:distance].to_i, altitude: pa[:altitude].to_i)
      end
    end
    creer_rep_photos(params[:creer_rep_photos]) unless params[:creer_rep_photos].blank?
    charge_photos_si_besoin
    @trace.materiel_ids = params[@class_symbol][:materiel_ids]
    @gpx_avant = params[:gpx_avant]
    fichier_gpx = traite_traces_si_besoin
    @trace.fichier_gpx = fichier_gpx unless fichier_gpx.nil?
    @trace.polylines = '[]' if @trace.fichier_gpx.blank?
    if @trace.save
      redirect_to @trace, notice: 'La randonnée a bien été créée.'
    else
      init_variables
      @garder_points = true
      render :new
    end
  end

  # GET /traces/1/edit
  def edit
    init_variables
    @garder_points = false
  end

  # PATCH/PUT /traces/1
  def update
    creer_rep_photos(params[:creer_rep_photos]) unless params[:creer_rep_photos].blank?
    charge_photos_si_besoin
    @gpx_avant = params[:gpx_avant]
    fichier_gpx = traite_traces_si_besoin
    @trace.fichier_gpx = fichier_gpx unless fichier_gpx.nil?
    @trace.polylines = '[]' if @trace.fichier_gpx.blank?
    @trace.materiel_ids = params[@class_symbol][:materiel_ids]
    if @trace.save
      redirect_to @trace, notice: 'La randonnée a bien été modifiée.'
    else
      init_variables
      @garder_points = false
      render :edit
    end
  end

  # renvoi dans le champ res le nombre de photos du répertoire sélectionné
  def photos_number
    if params[:rep].blank?
      render js: "$('strong#res').text('');"
    else
      repertoire = Rails.root.join('public', 'images', params[:rep])
      photos = Dir.entries(repertoire)
                  .select do |f|
        (!File.directory? File.join(repertoire, f)) &&
          File.extname(f).casecmp('.jpg').zero?
      end
      render js: "$('strong#res').text('#{photos.size}');"
    end
  end

  private

  #
  # crée le répertoire photo si nécessaire
  def creer_rep_photos(rep)
    repertoire = Rails.root.join('public', 'images', rep)
    Dir.mkdir(repertoire) unless Dir.exist?(repertoire)
    @trace.repertoire_photos = rep
  end

  # initialise les variables nécessaires à la construction
  # de la page à afficher
  def init_variables
    @gpx_candidats = gpx_candidats
    @rep_photos_candidats = rep_photos_candidats
    @gpx_avant = gpx_avant
  end

  # corrige la page demandée si nécessaire
  def corrige_page?
    if params[:idpage].nil?
      redirect_to action: action_name, idpage: 1
      nil
    else
      @traces = yield
      @nb_pages = [((@traces.size + TAILLE_PAGE) / TAILLE_PAGE).floor, 1].max
      if params[:idpage].to_i > @nb_pages
        redirect_to action: action_name, id: params[:id], idpage: @nb_pages
        nil
      else
        params[:idpage].to_i
      end
    end
  end

  # dresse la liste des répertoires de photos qui peuvent
  # être sélectionnés, c'est-à-dire ceux qui ne sont pas
  # référencés par une randonnée ou un trek
  def rep_photos_candidats
    classe = @trace.type == 'Randonnee' ? Randonnee : Trek
    repertoire = Rails.root.join('public', 'images')
    rep_photos_serveur = Dir.entries(repertoire)
                            .select do |f|
      (File.directory? File.join(repertoire, f)) &&
        !(['.', '..'].include? f)
    end
    rep_photos_base = classe.where.not(id: @trace.id)
                            .select(:repertoire_photos)
                            .distinct
                            .collect(&:repertoire_photos)
    rep_photos_serveur - rep_photos_base
  end

  # initialise le nom de la classe concernée
  def set_class
    @class_symbol = controller_name.classify.downcase.to_sym
  end

  # initialise la trace à traiter et vérifie son type
  def set_trace
    @trace = Trace.where(id: params[:id])
    if @trace.empty?
      redirect_back fallback_location: root_path,
                    notice: "La trace #{params[:id]} n'existe pas"
    elsif @trace.first.class.to_s.downcase.to_sym != @class_symbol
      redirect_back fallback_location: root_path,
                    notice: "La trace #{params[:id]} n'est pas du type #{@class_symbol}"
    end
    @trace = @trace.first
  end

  # teste si l'utilisateur est administrateur
  def test_admin
    if session[:admin].nil?
      if %w[destroy edit update].index(action_name)
        redirect_to @trace, notice: "Vous n'êtes pas administrateur"
      else
        redirect_to randonnees_url, notice: "Vous n'êtes pas administrateur"
      end
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def trace_params
    params.require(@class_symbol)
          .permit(:titre, :sous_titre, :description, :fichier_gpx,
                  :altitude_minimum, :altitude_maximum, :ascension_totale,
                  :descente_totale, :heure_debut, :heure_fin, :distance_totale,
                  :lat_depart, :long_depart, :lat_arrivee, :long_arrivee,
                  :type, :moyen, :repertoire_photos, :creer_rep_photos,
                  :polylines, points: %i[distance altitude], materiels: [],
                  gpx_candidats: [])
  end

  # charge les photos sélectionnées par l'utilisateur sur son pdt
  def charge_photos_si_besoin
    uploaded_io = params[:upload_photos]
    if uploaded_io.nil? || @trace.repertoire_photos.blank?
      nil
    else
      for photo in uploaded_io do
        File.open(Rails.root.join('public', 'images', @trace.repertoire_photos,
                                  photo.original_filename), 'wb') do |file|
          file.write(photo.read)
        end
      end
    end
  end
end
