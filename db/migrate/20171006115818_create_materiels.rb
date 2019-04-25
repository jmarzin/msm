class CreateMateriels < ActiveRecord::Migration[5.0]
  def change
    create_table :materiels do |t|
      t.string :nom
      t.text :description
      t.string :photo
      t.integer :poids
      t.boolean :reforme

      t.timestamps
    end
  end
end
