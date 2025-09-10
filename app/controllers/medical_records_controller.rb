class MedicalRecordsController < ApplicationController
  before_action :authorize_request
  before_action :set_medical_record, only: [:show, :update, :destroy]

  # GET /medical_records
  def index
    if @current_user.role == "doctor"
      # Doctors see records of their patients
      @medical_records = MedicalRecord.joins(:appointment)
                                      .where(appointments: { doctor_id: @current_user.id })
    elsif @current_user.role == "patient"
      # Patients see their own records
      @medical_records = @current_user.medical_records
    else
      @medical_records = MedicalRecord.none
    end

    render json: @medical_records, include: [:patient, :appointment, :prescriptions]
  end

  # GET /medical_records/:id
  def show
    if authorized_for_record?(@medical_record)
      render json: @medical_record, include: [:patient, :appointment, :prescriptions]
    else
      render json: { error: "Not authorized" }, status: :unauthorized
    end
  end

  # POST /medical_records
  def create
    unless @current_user.role == "doctor"
      return render json: { error: "Only doctors can create medical records" }, status: :forbidden
    end

    # Verify that appointment belongs to this doctor and patient matches
    appointment = Appointment.find_by(id: medical_record_params[:appointment_id])
    if appointment.nil? || appointment.doctor_id != @current_user.id || appointment.patient_id != medical_record_params[:patient_id].to_i
      return render json: { error: "Invalid appointment for this doctor or patient" }, status: :unprocessable_entity
    end

    @medical_record = MedicalRecord.new(medical_record_params)

    if @medical_record.save
      render json: @medical_record, status: :created
    else
      render json: { errors: @medical_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /medical_records/:id
  def update
    unless @current_user.role == "doctor" && @medical_record.appointment.doctor_id == @current_user.id
      return render json: { error: "Only doctors can update their patients' medical records" }, status: :forbidden
    end

    if @medical_record.update(medical_record_params)
      render json: @medical_record
    else
      render json: { errors: @medical_record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /medical_records/:id
  def destroy
    unless @current_user.role == "doctor" && @medical_record.appointment.doctor_id == @current_user.id
      return render json: { error: "Only doctors can delete their patients' medical records" }, status: :forbidden
    end

    @medical_record.destroy
    head :no_content
  end

  private

  def set_medical_record
    @medical_record = MedicalRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Medical record not found" }, status: :not_found
  end

  def authorized_for_record?(record)
    (@current_user.role == "doctor" && record.appointment.doctor_id == @current_user.id) ||
      (@current_user.role == "patient" && record.patient_id == @current_user.id)
  end

  def medical_record_params
    params.require(:medical_record).permit(:patient_id, :appointment_id, :diagnosis,:treatment, :notes)
  end
end
