class Billing < ApplicationRecord
  # billing.rb
belongs_to :appointment
validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
validates :status, inclusion: { in: ["unpaid", "paid"] }
# Scopes
  scope :paid, -> { where(status: 'paid') }
  scope :unpaid, -> { where(status: 'unpaid') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Class method for total revenue
  def self.total_revenue
    paid.sum(:amount)
  end
  
  # Mark billing as paid after successful Stripe payment
  def mark_as_paid!(payment_intent_id)
    update!(
      status: 'paid',
      payment_intent_id: payment_intent_id,
      paid_at: Time.current
    )
  end
  
  # Generate a unique order ID for Stripe
  def order_id
    "BILL-#{id}"
  end
  
  # Get customer email from appointment
  def customer_email
    appointment.patient.email rescue nil
  end
end
