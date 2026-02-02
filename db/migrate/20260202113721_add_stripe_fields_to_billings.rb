class AddStripeFieldsToBillings < ActiveRecord::Migration[8.0]
  def change
    add_column :billings, :session_id, :string
    add_column :billings, :payment_intent_id, :string
    add_column :billings, :paid_at, :datetime

    add_index :billings, :session_id
    add_index :billings, :payment_intent_id
  end
end
