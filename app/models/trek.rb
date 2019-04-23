##
# classe de gestion des treks
class Trek < Trace
  has_many :randonnees, class_name: 'Trace', foreign_key: 'traces_id',
                        dependent: :nullify
  # fusionne les gpx fournis
  # retourne le nom du fichier créé
  def fusionne(gpx, gpx_avant)
    unless gpx.is_a?(Array) &&
        !gpx.empty? &&
        gpx[0].is_a?(String)
      raise 'la méthode fusionne attend un tableau de String'
    end

    fichier_trek = if self.id.nil?
                     "#{Trace.find_by_sql("SELECT nextval('traces_id_seq') AS trace_id")[0].trace_id + 1}.gpx"
                   else
                     "#{id}.gpx"
                   end
    liste_a_traiter_rust = { resultat: Rails.root.join('public', 'gpx', 'treks',
                                          fichier_trek).to_s, fichiers: [] }
    fichiers_a_traiter_donnees  = []
    if gpx_avant != [''] && gpx - gpx_avant == [gpx.last]
      liste_a_traiter_rust[:fichiers] = liste_a_traiter_rust[:fichiers] <<
                                        Rails.root.join('public', 'gpx', 'treks',
                                                        fichier_trek).to_s
      fichiers_a_traiter_donnees << fichier_trek
      liste_a_traiter_rust[:fichiers] = liste_a_traiter_rust[:fichiers] <<
                                        Rails.root.join('public', 'gpx', 'randos',
                                                        gpx.last).to_s
      fichiers_a_traiter_donnees << gpx.last
    else
      gpx.each do |nom|
        liste_a_traiter_rust[:fichiers] = liste_a_traiter_rust[:fichiers] <<
                                          Rails.root.join('public', 'gpx', 'randos',
                                                         nom).to_s
        fichiers_a_traiter_donnees << nom
      end
    end
    traces = Trace.where(fichier_gpx: fichiers_a_traiter_donnees).order(:heure_debut)
    self.altitude_minimum = traces.minimum('altitude_minimum')
    self.altitude_maximum = traces.maximum('altitude_maximum')
    self.ascension_totale = traces.sum('ascension_totale')
    self.descente_totale = traces.sum('descente_totale')
    self.heure_debut = traces.first.heure_debut
    self.heure_fin = traces.last.heure_fin
    self.distance_totale = traces.sum('distance_totale')
    self.lat_depart = traces.first.lat_depart
    self.long_depart = traces.first.long_depart
    self.lat_arrivee = traces.last.lat_arrivee
    self.long_arrivee = traces.last.long_arrivee
    resultat = JSON.parse(GpxTraite.traite_liste_fichiers(ActiveSupport::JSON.encode(liste_a_traiter_rust)))
    self.polylines = resultat['profil'].to_json
    fichier_trek

  end

end
