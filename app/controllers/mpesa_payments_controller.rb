# app/controllers/mpesa_payments_controller.rb
class MpesaPaymentsController < ApplicationController
  before_action :authorize_request, except: [:callback]

  # POST /billings/:id/mpesa_payment
  def create
    billing = Billing.find(params[:id])
    
    # Verify user owns this billing
    unless billing.appointment.patient_id == @current_user.id
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    phone_number = params[:phone_number]
    amount = params[:amount] || billing.amount

    Rails.logger.info "=== M-Pesa Payment Request ==="
    Rails.logger.info "Phone: #{phone_number}"
    Rails.logger.info "Amount: #{amount}"
    Rails.logger.info "Billing ID: #{billing.id}"

    # Initiate STK Push
    result = MpesaService.stk_push(
      phone_number: phone_number,
      amount: amount,
      account_reference: "BILL-#{billing.id}",
      transaction_desc: "Payment for Appointment ##{billing.appointment_id}"
    )

    Rails.logger.info "=== M-Pesa Response ==="
    Rails.logger.info result.inspect

    if result[:success]
      # Store the checkout request ID for callback verification
      billing.update(
        mpesa_checkout_request_id: result[:checkout_request_id],
        mpesa_merchant_request_id: result[:merchant_request_id]
      )

      render json: {
        success: true,
        message: 'Payment request sent. Please check your phone.',
        checkout_request_id: result[:checkout_request_id]
      }
    else
      Rails.logger.error "M-Pesa payment failed: #{result[:error]}"
      render json: {
        success: false,
        error: result[:error] || 'M-Pesa payment failed'
      }, status: :unprocessable_content
    end
  rescue => e
    Rails.logger.error "M-Pesa payment exception: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { 
      success: false,
      error: e.message 
    }, status: :internal_server_error
  end

  # POST /mpesa/callback (Safaricom will call this)
  def callback
    callback_data = params[:Body][:stkCallback]
    
    checkout_request_id = callback_data[:CheckoutRequestID]
    result_code = callback_data[:ResultCode]

    billing = Billing.find_by(mpesa_checkout_request_id: checkout_request_id)

    if billing
      if result_code == 0
        # Payment successful
        callback_metadata = callback_data[:CallbackMetadata][:Item]
        
        mpesa_receipt = callback_metadata.find { |item| item[:Name] == 'MpesaReceiptNumber' }&.dig(:Value)
        phone_number = callback_metadata.find { |item| item[:Name] == 'PhoneNumber' }&.dig(:Value)
        
        billing.update(
          status: 'paid',
          mpesa_receipt_number: mpesa_receipt,
          mpesa_phone_number: phone_number,
          paid_at: Time.current
        )
      else
        # Payment failed or cancelled
        billing.update(
          mpesa_result_desc: callback_data[:ResultDesc]
        )
      end
    end

    render json: { ResultCode: 0, ResultDesc: 'Success' }
  end
end