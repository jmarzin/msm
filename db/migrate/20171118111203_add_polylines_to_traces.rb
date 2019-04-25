class AddPolylinesToTraces < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        add_column :traces, :polylines, :string, default: '[]'
      end
      dir.down do
        remove_column :traces, :polylines, :string
      end
    end
  end
end
