class BillingsController < ApplicationController
  before_action :authorize_request
  before_action :set_billing, only: [:show, :update, :destroy]
  before_action :set_appointment, only: [:index, :create]

  # GET /appointments/:appointment_id/billings
  def index
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_appointment?(@appointment)

    render json: @appointment.billing ? [@appointment.billing] : []
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
    return render json: { error: "Only doctors can update billings" }, status: :forbidden unless @current_user.role == "doctor"

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
    params.require(:billing).permit(:amount, :status, :notes)
  end
end
