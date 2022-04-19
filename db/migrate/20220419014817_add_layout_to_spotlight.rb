class AddLayoutToSpotlight < ActiveRecord::Migration[5.2]
  def change
    add_column :spotlights, :layout, :text
    remove_column :spotlights, :map_title, :string
    remove_column :spotlights, :map_description, :string
    remove_column :spotlights, :map_date, :string
    remove_column :spotlights, :map_image, :string
    remove_column :spotlights, :map_place, :string
    remove_column :spotlights, :map_country, :string
    remove_column :spotlights, :map_languages, :string
  end
end
