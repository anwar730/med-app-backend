class CreatePrescriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :prescriptions do |t|
      t.string :medication_name
      t.string :dosage
      t.text :instructions
      t.integer :medical_record_id

      t.timestamps
    end
  end
end
