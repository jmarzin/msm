class CreateTraces < ActiveRecord::Migration[5.1]
  def change
    create_table :traces do |t|
      t.belongs_to :traces, index: true
      t.string :titre
      t.string :sous_titre
      t.text :description
      t.string :fichier_gpx
      t.integer :altitude_minimum
      t.integer :altitude_maximum
      t.integer :ascension_totale
      t.integer :descente_totale
      t.date :heure_debut
      t.date :heure_fin
      t.integer :distance_totale
      t.decimal :lat_depart
      t.decimal :long_depart
      t.decimal :lat_arrivee
      t.decimal :long_arrivee
      t.string :type

      t.timestamps
    end
  end
end
