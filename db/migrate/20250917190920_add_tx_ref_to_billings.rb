class AddTxRefToBillings < ActiveRecord::Migration[8.0]
  def change
    add_column :billings, :tx_ref, :string
  end
end
