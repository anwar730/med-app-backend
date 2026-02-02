class BillingsController < ApplicationController
  before_action :authorize_request
  before_action :set_billing, only: [:show, :update, :destroy, :create_checkout_session, :verify_payment]
  before_action :set_appointment, only: [:index, :create]

  # GET /appointments/:appointment_id/billings
  def index
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_appointment?(@appointment)

    render json: @appointment.billing ? [@appointment.billing] : []
  end
  # GET /admin/billings
def all_billings
  return render json: { error: "Only admin can view all billings" }, status: :forbidden unless @current_user.role == "admin"

  billings = Billing.includes(:appointment).all
  render json: billings.as_json(include: { appointment: { include: :patient } })
end


  # GET /billings/:id
  def show
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_billing?(@billing)

    render json: @billing
  end

  # POST /appointments/:appointment_id/billings
  def create
    return render json: { error: "Only doctors can create billings" }, status: :forbidden unless @current_user.role == "doctor"

    @billing = @appointment.build_billing(billing_params)
    if @billing.save
      render json: @billing, status: :created
    else
      render json: { errors: @billing.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /billings/:id
  def update
    return render json: { error: "Only doctors can update billings" }, status: :forbidden unless @current_user.role == "admin"

    if @billing.update(billing_params)
      render json: @billing
    else
      render json: { errors: @billing.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /billings/:id
  def destroy
    return render json: { error: "Only doctors can delete billings" }, status: :forbidden unless @current_user.role == "doctor"

    @billing.destroy
    head :no_content
  end

  # ========== NEW STRIPE PAYMENT METHODS ==========

  # POST /billings/:id/create_checkout_session
  def create_checkout_session
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_billing?(@billing)
    return render json: { error: "Billing already paid" }, status: :unprocessable_entity if @billing.status == "paid"

    begin
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'kes',
            product_data: {
              name: 'Medical Appointment Payment',
              description: "Payment for Appointment ##{@billing.appointment_id}"
            },
            unit_amount: (@billing.amount * 100).to_i # Amount in cents
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: "#{ENV['FRONTEND_URL']}/payment/success?billing_id=#{@billing.id}",
        cancel_url: "#{ENV['FRONTEND_URL']}/payment/cancel",
        client_reference_id: @billing.id.to_s,
        customer_email: @billing.appointment.patient.email,

        metadata: {
          billing_id: @billing.id,
          appointment_id: @billing.appointment_id,
          patient_id: @billing.appointment.patient_id
        }
      )

      # Update billing with session ID
      @billing.update!(session_id: session.id)

      render json: { 
        sessionId: session.id, 
        url: session.url 
      }, status: :ok

    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # GET /billings/:id/verify_payment
  def verify_payment
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_billing?(@billing)

    begin
      return render json: { error: "No payment session found" }, status: :not_found unless @billing.session_id

      session = Stripe::Checkout::Session.retrieve(@billing.session_id)

      if session.payment_status == 'paid'
        @billing.mark_as_paid!(session.payment_intent)

        render json: {
          status: 'paid',
          billing_id: @billing.id,
          amount: session.amount_total / 100.0
        }, status: :ok
      else
        render json: { status: session.payment_status }, status: :ok
      end

    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /billings/stats (for admin dashboard)
  def stats
    return render json: { error: "Only admin can view stats" }, status: :forbidden unless @current_user&.role == "admin"

    render json: {
      total_billings: Billing.count,
      total_revenue: Billing.total_revenue,
      paid_count: Billing.paid.count,
      unpaid_count: Billing.unpaid.count,
      recent_billings: Billing.recent.limit(10)
    }, status: :ok
  end


  private

  def set_billing
    @billing = Billing.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Billing not found" }, status: :not_found
  end

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Appointment not found" }, status: :not_found
  end

  def authorized_for_appointment?(appointment)
    (@current_user.role == "doctor" && appointment.doctor_id == @current_user.id) ||
      (@current_user.role == "patient" && appointment.patient_id == @current_user.id)
  end

  def authorized_for_billing?(billing)
    authorized_for_appointment?(billing.appointment)
  end

  def billing_params
    params.require(:billing).permit(:amount, :status, :appointment_id)
  end
end
