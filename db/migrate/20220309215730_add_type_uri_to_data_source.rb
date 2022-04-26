class AddTypeUriToDataSource < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :type_uri, :string
  end
end
