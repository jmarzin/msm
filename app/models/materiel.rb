##
# classe de gestion des matériels emportés
class Materiel < ApplicationRecord

  # fournit une description courte du matériel
  # limité à 120 caractères. La mise en forme html est perdue
  def description_courte
    desc = HTMLEntities.new.decode(self.description.gsub(/<.*?>/, ''))
    coupure = desc.index(' ', 120)
    if coupure.nil?
      desc
    else
      desc[0, coupure] + ' ...'
    end
  end

  # facilite la sélection des items emportés
  # renvoie le nom, le poids et une éventuelle mention de réforme
  def nom_poids_et_reforme
    nom + ' : ' + poids.to_s + ' g ' + (self.reforme ? '(réformé)' : '')
  end

  validates :nom, presence: true
  validates :description, presence: true
  validates :photo, presence: true
  validates :poids, presence: true, numericality: { only_integer: true}

  has_and_belongs_to_many :traces
end
