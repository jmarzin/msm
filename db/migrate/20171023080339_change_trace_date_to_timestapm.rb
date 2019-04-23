class ChangeTraceDateToTimestapm < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      change_table :traces do |t|
        dir.up do
          t.change :heure_debut, :timestamp
          t.change :heure_fin, :timestamp
        end
        dir.down do
          t.change :heure_debut, :date
          t.change :heure_fin, :timestamp
        end
      end
    end
  end
end
