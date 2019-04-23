class CreatePoints < ActiveRecord::Migration[5.1]
  def change
    create_table :points do |t|
      t.integer :distance
      t.integer :altitude
      t.belongs_to :trace, index: true
    end
  end
end
