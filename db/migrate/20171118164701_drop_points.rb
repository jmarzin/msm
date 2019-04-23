class DropPoints < ActiveRecord::Migration[5.1]
  def up
    drop_table :points
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
