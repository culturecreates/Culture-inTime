class AddFetchMethodToDataSource < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :fetch_method, :string
  end
end
