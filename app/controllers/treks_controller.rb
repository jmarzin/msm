##
# classe de contrôle des treks. Elle hérite du contrôle
# des traces
class TreksController < TracesController
  before_action :set_class
  before_action :set_trace, only: %i[show edit update destroy]
  before_action :test_admin, only: %i[edit update destroy new create]
  before_action :set_menu

  # GET /treks/1
  def show
    if @trace.repertoire_photos.blank?
      @photos = []
      @trace.randonnees.reject { |r| r.repertoire_photos.blank? }.each do |r|
        repertoire = Rails.root.join('public', 'images', r.repertoire_photos)
        @photos += Dir.entries(repertoire).sort
                       .select { |f| File.extname(f).casecmp('.JPG').zero? }
                       .map { |f| File.join('/images', r.repertoire_photos, f) }
      end
    end
    super
  end

  # affiche le trek projet
  def a_propos
    session[:menu] = 'A propos'
    @trek = Trek.where(titre: 'Le projet')
    if @trek.empty?
      redirect_to root_url
    else
      @trace = @trek.first
      show
      render 'show'
    end
  end

  # POST /treks
  # l'essentiel du traitement est géré dans la classe trace
  def create
    @trace = Trace.new(trace_params)
    @trace.randonnee_ids = params[@class_symbol][:randonnee_ids]
    super
  end

  # PATCH/PUT /treks/1
  # l'essentiel du traitement est géré dans la classe trace
  def update
    @trace.assign_attributes(trace_params)
    @trace.randonnee_ids = params[@class_symbol][:randonnee_ids]
    super
  end

  # DELETE /treks/1
  def destroy
    fichier = File.join('public', 'gpx', 'treks', "#{@trace.id}.gpx")
    File.delete(fichier) if File.exist?(fichier)
    @trace.destroy
    redirect_to treks_url, notice: 'La randonnée a bien été supprimée.'
  end

  private

  # dresse la liste des traces candidates, celles qui ne sont
  # pas liées à un autre trek
  def gpx_candidats
    Randonnee.where("traces_id IS NULL AND  fichier_gpx <> ''")
             .order(:fichier_gpx)
  end

  # conserve la liste des randonnées sélectionnées lors de la
  # dernière transaction
  def gpx_avant
    @trace.fichier_gpx.blank? || @trace.randonnees.empty? ? [''] : @trace.randonnees.collect(&:fichier_gpx).sort
  end

  # lance le traitement de fusion des traces des randonnées
  # uniquement si c'est nécessaire
  def traite_traces_si_besoin
    @gpx_apres = @trace.randonnees.collect(&:fichier_gpx).sort
    (@gpx_avant <=> @gpx_apres).zero? || @gpx_apres.empty? ? nil : @trace.fusionne(@gpx_apres, @gpx_avant)
  end

  # détermine l'item du menu qui doit être mis en évidence
  def set_menu
    session[:menu] = 'Treks'
  end
end