class User < ApplicationRecord
  has_secure_password

  # Doctor appointments
  has_many :doctor_appointments, class_name: "Appointment", foreign_key: "doctor_id"
  has_many :patients, through: :doctor_appointments, source: :patient

  # Patient appointments
  has_many :patient_appointments, class_name: "Appointment", foreign_key: "patient_id"
  has_many :doctors, through: :patient_appointments, source: :doctor

  # Medical records (for patients)
  has_many :medical_records, foreign_key: "patient_id"
end
