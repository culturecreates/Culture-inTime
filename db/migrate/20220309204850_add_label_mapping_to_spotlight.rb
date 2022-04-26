class AddLabelMappingToSpotlight < ActiveRecord::Migration[5.2]
  def change
    add_column :spotlights, :map_title, :string
    add_column :spotlights, :map_description, :string
    add_column :spotlights, :map_date, :string
    add_column :spotlights, :map_image, :string
    add_column :spotlights, :map_place, :string
    add_column :spotlights, :map_country, :string
    add_column :spotlights, :map_languages, :string
  end
end
