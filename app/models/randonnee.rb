##
# classe de gestion des randonnées
# elle hérite de la class trace
class Randonnee < Trace
  belongs_to :trek, class_name: 'Trace', foreign_key: 'traces_id', optional: true

  # pour faciliter le choix des randonnées composant un trek
  # fournit le nom du fichier gpx suivi du titre de la randonnée
  def fichier_titre
    fichier_gpx + ' ' + titre
  end
end