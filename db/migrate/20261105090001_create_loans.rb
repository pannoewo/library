class CreateLoans < ActiveRecord::Migration[8.0]
  def change
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true, index: false
      t.references :reader, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.datetime :due_at, null: false
      t.datetime :returned_at
      t.datetime :advance_reminder_sent_at
      t.datetime :due_reminder_sent_at
      t.timestamps
    end

    add_index :loans, :book_id,
      unique: true,
      where: "returned_at IS NULL",
      name: "index_loans_on_book_id_when_active"
  end
end
