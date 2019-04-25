class CreateMaterielsTraces < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        create_table :materiels_traces do |t|
          t.belongs_to :trace, index: true
          t.belongs_to :materiel, index: false
        end
      end
      dir.down do
        drop_table :materiels_traces
      end
    end
  end
end