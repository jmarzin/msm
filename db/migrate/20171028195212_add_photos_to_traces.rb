class AddPhotosToTraces < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        add_column :traces, :repertoire_photos, :string
      end
      dir.down do
        remove_column :traces, :repertoire_photos, :string
      end
    end
  end
end
