class AddConsultationFeeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :consultation_fee, :decimal
  end
end
