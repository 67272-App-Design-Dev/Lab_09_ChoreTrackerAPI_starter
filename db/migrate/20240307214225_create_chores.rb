class CreateChores < ActiveRecord::Migration[7.0]
  def change
    create_table :chores do |t|
      t.references :child, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.date :due_on
      t.boolean :completed

      # t.timestamps
    end
  end
end
