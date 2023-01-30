class AddApiToSpotlight < ActiveRecord::Migration[5.2]
  def change
    add_column :spotlights, :language, :string
    add_column :spotlights, :frame, :text
  end
end
