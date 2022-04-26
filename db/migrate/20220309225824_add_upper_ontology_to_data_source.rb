class AddUpperOntologyToDataSource < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :upper_title, :string
    add_column :data_sources, :upper_description, :string
    add_column :data_sources, :upper_date, :string
    add_column :data_sources, :upper_image, :string
    add_column :data_sources, :upper_place, :string
    add_column :data_sources, :upper_country, :string
    add_column :data_sources, :upper_languages, :string
  end
end
