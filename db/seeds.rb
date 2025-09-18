# Clear old data
Billing.destroy_all
Prescription.destroy_all
MedicalRecord.destroy_all
Appointment.destroy_all
User.destroy_all

puts "Seeding users..."

# Doctors
doctor1 = User.create!(
  name: "Dr. John Smith",
  email: "drjohn@example.com",
  password: "password",
  role: "doctor"
)

doctor2 = User.create!(
  name: "Dr. Mary Brown",
  email: "drmary@example.com",
  password: "password",
  role: "doctor"
)

# Patients
patient1 = User.create!(
  name: "Alice Johnson",
  email: "alice@example.com",
  password: "password",
  role: "patient"
)

patient2 = User.create!(
  name: "Bob Williams",
  email: "bob@example.com",
  password: "password",
  role: "patient"
)

patient3 = User.create!(
  name: "Charlie Davis",
  email: "charlie@example.com",
  password: "password",
  role: "patient"
)

puts "Seeding appointments..."

# Appointments
appt1 = Appointment.create!(
  doctor_id: doctor1.id,
  patient_id: patient1.id,
  appointment_date: Date.today,
  scheduled_at: Time.now.change(hour: 10, min: 0),
  status: "scheduled",
  notes: "Patient has flu symptoms"
)

appt2 = Appointment.create!(
  doctor_id: doctor1.id,
  patient_id: patient2.id,
  appointment_date: Date.today + 1,
  scheduled_at: Time.now.change(hour: 14, min: 0),
  status: "scheduled",
  notes: "Back pain consultation"
)

appt3 = Appointment.create!(
  doctor_id: doctor2.id,
  patient_id: patient3.id,
  appointment_date: Date.today + 2,
  scheduled_at: Time.now.change(hour: 11, min: 30),
  status: "scheduled",
  notes: "Routine checkup"
)

puts "Seeding medical records..."

# Medical Records
record1 = MedicalRecord.create!(
  patient_id: patient1.id,
  appointment_id: appt1.id,
  diagnosis: "Flu",
  treatment: "Rest and hydration",
  notes: "Prescribed paracetamol"
)

record2 = MedicalRecord.create!(
  patient_id: patient2.id,
  appointment_id: appt2.id,
  diagnosis: "Muscle strain",
  treatment: "Physiotherapy",
  notes: "Prescribed ibuprofen"
)

record3 = MedicalRecord.create!(
  patient_id: patient3.id,
  appointment_id: appt3.id,
  diagnosis: "Healthy",
  treatment: "None",
  notes: "No treatment required"
)

puts "Seeding prescriptions..."

# Prescriptions
Prescription.create!(
  medical_record_id: record1.id,
  medication_name: "Paracetamol",
  dosage: "500mg",
  instructions: "Take twice a day after meals"
)

Prescription.create!(
  medical_record_id: record2.id,
  medication_name: "Ibuprofen",
  dosage: "200mg",
  instructions: "Take once every 8 hours"
)

Prescription.create!(
  medical_record_id: record3.id,
  medication_name: "Vitamin D",
  dosage: "1000 IU",
  instructions: "One tablet daily"
)

puts "Seeding billings..."

# Billings
Billing.create!(
  appointment_id: appt1.id,
  amount: 5000,
  status: "unpaid"
)

Billing.create!(
  appointment_id: appt2.id,
  amount: 8000,
  status: "paid"
)

Billing.create!(
  appointment_id: appt3.id,
  amount: 3000,
  status: "unpaid"
)

puts "✅ Seeding completed!"


#  {
# "email": "admin@hospital.com",
#   "password": "password123"
#   }