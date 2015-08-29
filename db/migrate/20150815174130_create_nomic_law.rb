class CreateNomicLaw < ActiveRecord::Migration
  def change
    create_table :laws do |t|
      t.belongs_to :superseded_law, class_name: "Law", index: true
      t.belongs_to :author, class_name: "Person", index: true
      t.integer :rule_number
      t.text :text
      t.boolean :mutable, default: true
      t.boolean :repealed, default: false
      t.timestamps null: false
    end
  end
end
