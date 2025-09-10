class CreateBillings < ActiveRecord::Migration[8.0]
  def change
    create_table :billings do |t|
      t.decimal :amount
      t.string :status
      t.integer :appointment_id

      t.timestamps
    end
  end
end
