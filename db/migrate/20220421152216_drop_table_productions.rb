class DropTableProductions < ActiveRecord::Migration[5.2]
  def change
    drop_table :productions
  end
end
