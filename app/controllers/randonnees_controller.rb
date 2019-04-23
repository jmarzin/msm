##
# classe de contrôle des randonnées. Elle hérite du contrôle
# des traces
class RandonneesController < TracesController
  before_action :set_class
  before_action :set_trace, only: %i[show edit update destroy]
  before_action :test_admin, only: %i[edit update destroy new create]
  before_action :set_menu

  # GET /randonnees/trek/1/page/1
  # affiche la liste des randonnees du trek d'id 1
  def trek_index
    @trace = Trek.where(id: params[:id])
    # traitement du cas où la trace indiquée n'est pas un trek
    if @trace.empty?
      return redirect_to treks_url,
                         notice: "le trek #{params[:id].to_i} n'existe pas."
    end
    @trace = @trace.first
    # traitement du cas nominal
    return if (@page_a_afficher = corrige_page? do
                 @trace.randonnees.order(heure_debut: :desc)
               end).nil?
    @traces = @traces.to_a.slice((@page_a_afficher - 1) * TAILLE_PAGE,
                                 TAILLE_PAGE)
  end

  # POST /randonnees
  # l'essentiel du traitement est commun aux randonnées et aux treks
  # on garde la création de la trace ici car c'est indispensable pour
  # les treks
  def create
    @trace = Trace.new(trace_params)
    super
  end

  # PATCH/PUT /randonnees/1
  # l'essentiel du traitement est commun aux randonnées et aux treks
  # on garde la création de la trace ici car c'est indispensable pour
  # les treks
  def update
    @trace.assign_attributes(trace_params)
    super
  end

  # DELETE /randonnees/1
  def destroy
    if @trace.traces_id.blank?
      @trace.destroy
      redirect_to randonnees_url, notice: 'La randonnée a bien été supprimée.'
    else
      redirect_to randonnee_url(@trace), notice: 'La randonnée ne peut pas être supprimée.'
    end
  end

  private

  # les fichiers candidats sont ceux qui figurent dans le répertoire
  # et ne sont pas déjà affectés à une randonnée
  def gpx_candidats
    repertoire = Rails.root.join('public', 'gpx', 'randos')
    gpx_repertoire = Dir.entries(repertoire)
                        .select do |f|
      (!File.directory? File.join(repertoire, f)) &&
        File.extname(f).casecmp('.GPX').zero?
    end
    gpx_base = Randonnee.where.not(id: @trace.id)
                        .select(:fichier_gpx)
                        .distinct
                        .collect(&:fichier_gpx)
    (gpx_repertoire - gpx_base).sort
  end

  # pour garder dans la page la valeur du fichier
  # à l'issue de la transaction précédente

  def gpx_avant
    @trace.fichier_gpx.blank? ? [''] : [@trace.fichier_gpx]
  end

  # on ne traite la trace que si c'est nécessaire,
  # c'est-à-dire si on a changé le fichier à utiliser
  # soit par téléchargement
  # soit en sélectionnant un autre fichier sur le serveur
  def traite_traces_si_besoin
    uploaded_io = params[@class_symbol][:nouveau_fichier_gpx]
    if uploaded_io.nil?
      @trace.maj unless @trace.fichier_gpx.blank? ||
                        @trace.fichier_gpx == @gpx_avant[0]
      nil
    else
      File.open(Rails.root.join('public', 'gpx',
                                @trace.class == Randonnee ? 'randos' : 'treks',
                                uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      @trace.fichier_gpx = uploaded_io.original_filename
      @trace.maj
      uploaded_io.original_filename
    end
  end

  # fixe l'item du menu à mettre en évidence
  def set_menu
    session[:menu] = 'Randos'
  end
end
