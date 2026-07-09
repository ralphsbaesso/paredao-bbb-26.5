class CreatePartcipants < ActiveRecord::Migration[8.1]
  def change
    create_table :partcipants do |t|
      t.string :nickname, null: false
      t.string :avatar, null: false
      t.boolean :eliminated, null: false, default: false

      t.timestamps
    end

    add_index :partcipants, :nickname, unique: true
  end
end
