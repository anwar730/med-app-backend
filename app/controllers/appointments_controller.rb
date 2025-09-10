class AppointmentsController < ApplicationController
  before_action :authorize_request
  before_action :set_appointment, only: [:show, :update, :destroy]

  # GET /appointments
  def index
    if @current_user.role == "doctor"
      @appointments = Appointment.where(doctor_id: @current_user.id)
    elsif @current_user.role == "patient"
      @appointments = Appointment.where(patient_id: @current_user.id)
    else
      @appointments = Appointment.none
    end
    render json: @appointments, include: [:doctor, :patient]
  end

  # GET /appointments/:id
  def show
    if authorized_for_appointment?(@appointment)
      render json: @appointment, include: [:doctor, :patient, :medical_record, :billing]
    else
      render json: { error: "Not authorized" }, status: :unauthorized
    end
  end

  # POST /appointments
  def create
  doctor = User.find(params[:appointment][:doctor_id])
  patient = User.find(params[:appointment][:patient_id])

  unless doctor.role == "doctor"
    return render json: { error: "Selected doctor_id is not a doctor" }, status: :unprocessable_entity
  end

  unless patient.role == "patient"
    return render json: { error: "Selected patient_id is not a patient" }, status: :unprocessable_entity
  end

  @appointment = Appointment.new(appointment_params)
  if @appointment.save
    render json: @appointment, status: :created
  else
    render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
  end
end


  # PATCH/PUT /appointments/:id
  def update
    if authorized_for_appointment?(@appointment) && @appointment.update(appointment_params)
      render json: @appointment
    else
      render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
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
    params.require(:appointment).permit(:appointment_date,:doctor_id, :patient_id, :scheduled_at, :notes)
  end
end
