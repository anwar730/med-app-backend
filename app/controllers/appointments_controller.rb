class AppointmentsController < ApplicationController
  before_action :authorize_request
  before_action :set_appointment, only: [:show, :update, :destroy, :confirm, :start, :complete, :cancel]

  # GET /appointments
  def index
    if @current_user.role == "doctor"
      @appointments = Appointment.where(doctor_id: @current_user.id)
                                 .includes(:patient, :doctor, :medical_record, :billing)
    elsif @current_user.role == "patient"
      @appointments = Appointment.where(patient_id: @current_user.id)
                                 .includes(:doctor, :medical_record, :billing)
    else
      @appointments = Appointment.all.includes(:doctor, :patient, :medical_record, :billing)
    end

    render json: @appointments, include: {
      doctor: {},
      patient: {},
      medical_record: { include: :prescriptions },
      billing: {}
    }
  end

  # GET /appointments/:id
  def show
    appointment = Appointment.find(params[:id])
    render json: appointment, include: {
      doctor: {},
      patient: {},
      medical_record: { include: :prescriptions },
      billing: {}
    }
  end

  # POST /appointments
  def create
    doctor = User.find(params[:doctor_id])
    patient = @current_user # logged-in user is the patient

    unless doctor.role == "doctor"
      return render json: { error: "Selected doctor_id is not a doctor" }, status: :unprocessable_entity
    end

    @appointment = Appointment.new(
      doctor: doctor,
      patient: patient,
      appointment_date: params[:date],
      scheduled_at: "#{params[:date]} #{params[:time]}",
      status: "pending",
      notes: params[:notes]
    )

    if @appointment.save
      render json: @appointment, status: :created
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /appointments/:id
  def update
  if authorized_for_appointment?(@appointment)
    if @appointment.update(appointment_params)
      render json: @appointment
    else
      Rails.logger.debug @appointment.errors.full_messages
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
    end
  else
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end


  # DELETE /appointments/:id
  def destroy
    if authorized_for_appointment?(@appointment)
      @appointment.destroy
      head :no_content
    else
      render json: { error: "Not authorized" }, status: :unauthorized
    end
  end

  # POST /appointments/:id/confirm
  def confirm
    if @current_user.role == "doctor" && @appointment.doctor_id == @current_user.id
      @appointment.update(status: "confirmed")
      render json: @appointment
    else
      render json: { error: "Only the assigned doctor can confirm this appointment" }, status: :forbidden
    end
  end

  # POST /appointments/:id/start
  def start
    if @current_user.role == "doctor" && @appointment.doctor_id == @current_user.id
      @appointment.update(status: "in_progress")
      render json: @appointment
    else
      render json: { error: "Only the assigned doctor can start this appointment" }, status: :forbidden
    end
  end

  # POST /appointments/:id/complete
  def complete
    if @current_user.role == "doctor" && @appointment.doctor_id == @current_user.id
      if @appointment.medical_record.present?
        @appointment.update(status: "completed")
        render json: @appointment
      else
        render json: { error: "Cannot complete without a medical record" }, status: :unprocessable_entity
      end
    else
      render json: { error: "Only the assigned doctor can complete this appointment" }, status: :forbidden
    end
  end

  # POST /appointments/:id/cancel
  def cancel
    if authorized_for_appointment?(@appointment)
      @appointment.update(status: "cancelled")
      render json: @appointment
    else
      render json: { error: "Not authorized" }, status: :forbidden
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Appointment not found" }, status: :not_found
  end

  def authorized_for_appointment?(appointment)
    (@current_user.role == "doctor" && appointment.doctor_id == @current_user.id) ||
      (@current_user.role == "patient" && appointment.patient_id == @current_user.id)
  end

  def appointment_params
    params.require(:appointment).permit(:appointment_date, :doctor_id, :patient_id, :scheduled_at, :notes, :status)
  end
end
