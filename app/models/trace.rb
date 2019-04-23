##
# ajoute au module math une fonction de conversion
# en radians d'un angle en degré
module Math
  def self.to_radians(angle)
    angle / 180 * Math::PI
  end
end

##
# classe de gestion des traces
class Trace < ApplicationRecord
  validates :titre, presence: true
  validates :sous_titre, presence: true
  validates :description, presence: true
  validates :altitude_minimum, allow_nil: true, numericality: { only_integer: true }
  validates :altitude_maximum, allow_nil: true, numericality: { only_integer: true }
  validates :ascension_totale, allow_nil: true, numericality: { only_integer: true }
  validates :descente_totale, allow_nil: true, numericality: { only_integer: true }
  validates :distance_totale, allow_nil: true, numericality: { only_integer: true }
  validates :lat_depart, allow_nil: true, numericality: true
  validates :lat_arrivee, allow_nil: true, numericality: true
  validates :long_depart, allow_nil: true, numericality: true
  validates :long_arrivee, allow_nil: true, numericality: true
  validates :lat_depart, presence: true, unless: :tout_vide?
  validates :lat_arrivee, presence: true, unless: :tout_vide?
  validates :long_depart, presence: true, unless: :tout_vide?
  validates :long_arrivee, presence: true, unless: :tout_vide?

  has_and_belongs_to_many :materiels, autosave: true
  accepts_nested_attributes_for :materiels

  # teste si aucune coordonnées, même partielle, n'est fournie
  def tout_vide?
    lat_arrivee.nil? && lat_depart.nil? && long_arrivee.nil? && long_depart.nil?
  end

  def maj
    resultat = JSON.parse(
      GpxTraite.traite_une_trace(
        Rails.root.join('public',
                        'gpx',
                        self.class == Randonnee ? 'randos' : 'treks',
                        fichier_gpx).to_s))
    self.heure_debut = resultat['heure_debut']
    self.heure_fin = resultat['heure_fin']
    self.long_depart = BigDecimal(resultat['lon_depart'].to_s)
    self.lat_depart = BigDecimal(resultat['lat_depart'].to_s)
    self.long_arrivee = BigDecimal(resultat['lon_arrivee'].to_s)
    self.lat_arrivee = BigDecimal(resultat['lat_arrivee'].to_s)
    self.altitude_minimum = resultat['altitude_mini'].to_i
    self.altitude_maximum = resultat['altitude_maxi'].to_i
    self.ascension_totale = resultat['cumul_montee'].to_i
    self.descente_totale = resultat['cumul_descente'].to_i
    self.distance_totale = resultat['distance'].to_i
    self.polylines = resultat['profil'].to_json
  end
end
