class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :gender, :string
    add_column :users, :dob, :date
    add_column :users, :specialization, :string
    add_column :users, :license_number, :string
    add_column :users, :workplace, :string
  end
end
