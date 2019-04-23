# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171118164701) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "materiels", id: :serial, force: :cascade do |t|
    t.string "nom"
    t.text "description"
    t.string "photo"
    t.integer "poids"
    t.boolean "reforme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "materiels_traces", force: :cascade do |t|
    t.bigint "trace_id"
    t.bigint "materiel_id"
    t.index ["trace_id"], name: "index_materiels_traces_on_trace_id"
  end

  create_table "traces", force: :cascade do |t|
    t.bigint "traces_id"
    t.string "titre"
    t.string "sous_titre"
    t.text "description"
    t.string "fichier_gpx"
    t.integer "altitude_minimum"
    t.integer "altitude_maximum"
    t.integer "ascension_totale"
    t.integer "descente_totale"
    t.datetime "heure_debut"
    t.datetime "heure_fin"
    t.integer "distance_totale"
    t.decimal "lat_depart"
    t.decimal "long_depart"
    t.decimal "lat_arrivee"
    t.decimal "long_arrivee"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "repertoire_photos"
    t.string "moyen"
    t.string "polylines", default: "[]"
    t.index ["traces_id"], name: "index_traces_on_traces_id"
  end

end
