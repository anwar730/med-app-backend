class PrescriptionsController < ApplicationController
  before_action :authorize_request
  before_action :set_prescription, only: [:show, :update, :destroy]
  before_action :set_medical_record, only: [:index, :create]

  # GET /medical_records/:medical_record_id/prescriptions
  def index
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_record?(@medical_record)

    render json: @medical_record.prescriptions
  end

  # GET /prescriptions/:id
  def show
    return render json: { error: "Not authorized" }, status: :unauthorized unless authorized_for_prescription?(@prescription)

    render json: @prescription
  end

  # POST /medical_records/:medical_record_id/prescriptions
  def create
    return render json: { error: "Only doctors can create prescriptions" }, status: :forbidden unless @current_user.role == "doctor"

    @prescription = @medical_record.prescriptions.new(prescription_params)
    if @prescription.save
      render json: @prescription, status: :created
    else
      render json: { errors: @prescription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /prescriptions/:id
  def update
    return render json: { error: "Only doctors can update prescriptions" }, status: :forbidden unless @current_user.role == "doctor"

    if @prescription.update(prescription_params)
      render json: @prescription
    else
      render json: { errors: @prescription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /prescriptions/:id
  def destroy
    return render json: { error: "Only doctors can delete prescriptions" }, status: :forbidden unless @current_user.role == "doctor"

    @prescription.destroy
    head :no_content
  end

  private

  def set_prescription
    @prescription = Prescription.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Prescription not found" }, status: :not_found
  end

  def set_medical_record
    @medical_record = MedicalRecord.find(params[:medical_record_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Medical record not found" }, status: :not_found
  end

  def authorized_for_record?(record)
    (@current_user.role == "doctor" && record.appointment.doctor_id == @current_user.id) ||
      (@current_user.role == "patient" && record.patient_id == @current_user.id)
  end

  def authorized_for_prescription?(prescription)
    authorized_for_record?(prescription.medical_record)
  end

  def prescription_params
    params.require(:prescription).permit(:medication_name, :dosage, :instructions)
  end
end
