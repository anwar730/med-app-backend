class AddPaymentMethodAndReferenceToBillings < ActiveRecord::Migration[8.0]
  def change
    add_column :billings, :payment_method, :string
    add_column :billings, :payment_reference, :string
  end
end
