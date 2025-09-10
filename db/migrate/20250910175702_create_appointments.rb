class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.datetime :appointment_date
      t.string :status
      t.integer :doctor_id
      t.integer :patient_id

      t.timestamps
    end
  end
end
