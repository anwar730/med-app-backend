class Billing < ApplicationRecord
  # billing.rb
belongs_to :appointment
validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
validates :status, inclusion: { in: ["unpaid", "paid"] }

end
