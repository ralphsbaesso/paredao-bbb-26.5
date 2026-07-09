class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.datetime :closed_at

      t.timestamps
    end

    add_index :events, :title, unique: true
  end
end
