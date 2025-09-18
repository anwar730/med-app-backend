class User < ApplicationRecord
  has_secure_password
  has_one_attached :cv


  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, confirmation: true

  ROLES = %w[patient pending_doctor rejected_doctor doctor admin].freeze
  validates :role, inclusion: { in: ROLES }

  # Associations
  has_many :doctor_appointments, class_name: "Appointment", foreign_key: "doctor_id", dependent: :destroy
  has_many :patients, through: :doctor_appointments, source: :patient

  has_many :patient_appointments, class_name: "Appointment", foreign_key: "patient_id", dependent: :destroy
  has_many :doctors, through: :patient_appointments, source: :doctor

  has_many :medical_records, foreign_key: "patient_id", dependent: :destroy

  # Scopes
  scope :pending_doctors, -> { where(role: "pending_doctor") }
  scope :reject_doctors, -> { where(role: "rejected_doctor") }
  scope :doctors, -> { where(role: "doctor") }
  scope :patients, -> { where(role: "patient") }
  scope :admins, -> { where(role: "admin") }

  # Helper methods
  def admin?; role == "admin"; end
  def doctor?; role == "doctor"; end
  def patient?; role == "patient"; end
  def pending_doctor?; role == "pending_doctor"; end
  def rejected_doctor?; role == "rejected_doctor"; end
end
