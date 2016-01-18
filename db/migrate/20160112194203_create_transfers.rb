class CreateTransfers < ActiveRecord::Migration
  def change
    create_table :transfers do |t|
      t.references :account, index: true, foreign_key: true
      t.references :event, index: true, foreign_key: true
      t.integer :amount_cents

      t.timestamps null: false
    end
  end
end
