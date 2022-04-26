class AddSparqlToSpotlight < ActiveRecord::Migration[5.2]
  def change
    add_column :spotlights, :sparql, :text
  end
end
