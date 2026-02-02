# app/controllers/webhooks_controller.rb

class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authorize_request

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: :bad_request
      return
    end

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      handle_successful_payment(session)

    when 'payment_intent.payment_failed'
      payment_intent = event.data.object
      handle_failed_payment(payment_intent)
    end

    render json: { received: true }, status: :ok
  end

  private

  def handle_successful_payment(session)
    billing_id = session.metadata.billing_id
    billing = Billing.find_by(id: billing_id)

    if billing && billing.status != 'paid'
      billing.mark_as_paid!(session.payment_intent)
      Rails.logger.info "Billing ##{billing_id} marked as paid via webhook"

      # Send confirmation email here if you have mailers set up
      # BillingMailer.payment_confirmation(billing).deliver_later
    end
  end

  def handle_failed_payment(payment_intent)
    Rails.logger.error "Payment failed: #{payment_intent.id}"
  end
end