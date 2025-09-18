class MedicalRecord < ApplicationRecord
  belongs_to :patient, class_name: "User"
  belongs_to :appointment

  has_many :prescriptions, dependent: :destroy
end
