class AddUpperPrefixToDataSource < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sources, :upper_prefix, :string
  end
end
