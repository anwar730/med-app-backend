class AddMpesaFieldsToBillings < ActiveRecord::Migration[7.0]
  def change
    add_column :billings, :mpesa_checkout_request_id, :string
    add_column :billings, :mpesa_merchant_request_id, :string
    add_column :billings, :mpesa_receipt_number, :string
    add_column :billings, :mpesa_phone_number, :string
    add_column :billings, :mpesa_result_desc, :string
    
    
    add_index :billings, :mpesa_checkout_request_id
    add_index :billings, :mpesa_receipt_number
  end
end