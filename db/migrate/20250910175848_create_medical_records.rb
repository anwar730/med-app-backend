class CreateMedicalRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :medical_records do |t|
      t.text :diagnosis
      t.text :treatment
      t.text :notes
      t.integer :patient_id
      t.integer :appointment_id

      t.timestamps
    end
  end
end
