class Appointment < ApplicationRecord
  belongs_to :doctor, class_name: "User"
  belongs_to :patient, class_name: "User"

  has_one :billing, dependent: :destroy
  has_one :medical_record, dependent: :destroy

  validates :status, inclusion: { in: %w[pending confirmed cancelled in_progress completed] }

  
end
