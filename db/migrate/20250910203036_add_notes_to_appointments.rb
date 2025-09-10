class AddNotesToAppointments < ActiveRecord::Migration[8.0]
  def change
    add_column :appointments, :notes, :text
  end
end
