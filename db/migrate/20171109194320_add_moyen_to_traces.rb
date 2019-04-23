class AddMoyenToTraces < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        add_column :traces, :moyen, :string
      end
      dir.down do
        remove_column :traces, :moyen, :string
      end
    end
  end
end
