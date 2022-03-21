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

ActiveRecord::Schema.define(version: 2022_03_17_182634) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chains", id: false, force: :cascade do |t|
    t.integer "data_source_id"
    t.integer "linked_data_source_id"
    t.index ["data_source_id", "linked_data_source_id"], name: "index_chains_on_data_source_id_and_linked_data_source_id", unique: true
    t.index ["linked_data_source_id", "data_source_id"], name: "index_chains_on_linked_data_source_id_and_data_source_id", unique: true
  end

  create_table "data_sources", force: :cascade do |t|
    t.string "name"
    t.text "sparql"
    t.string "email"
    t.datetime "loaded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type_uri"
    t.string "upper_title"
    t.string "upper_description"
    t.string "upper_date"
    t.string "upper_image"
    t.string "upper_place"
    t.string "upper_country"
    t.string "upper_languages"
    t.string "upper_prefix"
    t.string "fetch_method"
  end

  create_table "data_sources_spotlights", id: false, force: :cascade do |t|
    t.bigint "data_source_id"
    t.bigint "spotlight_id"
    t.index ["data_source_id"], name: "index_data_sources_spotlights_on_data_source_id"
    t.index ["spotlight_id"], name: "index_data_sources_spotlights_on_spotlight_id"
  end

  create_table "productions", force: :cascade do |t|
    t.string "label"
    t.string "location_label"
    t.string "location_uri"
    t.datetime "date_of_first_performance"
    t.string "production_company_uri"
    t.string "production_company_label"
    t.string "description"
    t.string "main_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.string "locality"
    t.string "production_uri"
    t.bigint "data_source_id"
    t.index ["data_source_id"], name: "index_productions_on_data_source_id"
  end

  create_table "spotlights", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "image"
    t.string "description"
    t.string "location"
    t.date "start_date"
    t.date "end_date"
    t.string "query"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "sparql"
    t.string "map_title"
    t.string "map_description"
    t.string "map_date"
    t.string "map_image"
    t.string "map_place"
    t.string "map_country"
    t.string "map_languages"
  end

  add_foreign_key "productions", "data_sources"
end
