class AdminController < ApplicationController
  before_action :authorize_request
  before_action :authorize_admin

  # ✅ Dashboard summary
  def summary
    stats = {
      total_users: User.count,
      total_doctors: User.where(role: "doctor").count,
      total_pending_doctors: User.where(role: "pending_doctor").count,
      total_patients: User.where(role: "patient").count,
      total_admins: User.where(role: "admin").count,

      total_appointments: Appointment.count,
      total_medical_records: MedicalRecord.count,
      total_prescriptions: Prescription.count,
      total_billings: Billing.count,
      total_revenue: Billing.where(status: "paid").sum(:amount)
    }

    render json: stats
  end

  # ✅ List all pending doctor applications
  def pending_doctors
  pending = User.where(role: "pending_doctor").map do |doc|
    doc.as_json(only: [:id, :name, :email, :specialization, :license_number,:consultation_fee, :workplace])
       .merge({
         cv_url: doc.cv.attached? ? url_for(doc.cv) : nil
       })
  end

  render json: pending
end
  # ✅ Approve doctor application
   def approve_doctor
    doctor = User.find(params[:id])
    if doctor.update_column(:role, "doctor") # ✅ direct DB update, skips validations
      render json: { message: "Doctor approved successfully" }, status: :ok
    else
      render json: { errors: "Failed to approve doctor" }, status: :unprocessable_entity
    end
  end

  # ✅ Reject doctor application
  def reject_doctor
  user = User.find(params[:id])

  if user.role == "pending_doctor"
    # Option 1: Explicit rejected role
    user.update_column(:role, "rejected_doctor")

    # Option 2 (your way): fallback to patient
    # user.update_column(:role, "patient")

    render json: { message: "#{user.name}'s doctor application was rejected" }, status: :ok
  else
    render json: { error: "User is not a pending doctor" }, status: :unprocessable_entity
  end
end


    def destroy_user
    user = User.find(params[:id])
    user.destroy
    render json: { message: "User deleted" }
  end

  # APPOINTMENTS MANAGEMENT
  def appointments
    render json: Appointment.all
  end

  def destroy_appointment
    appointment = Appointment.find(params[:id])
    appointment.destroy
    render json: { message: "Appointment deleted" }
  end

  # MEDICAL RECORDS MANAGEMENT
  def medical_records
    render json: MedicalRecord.all
  end

  def destroy_medical_record
    record = MedicalRecord.find(params[:id])
    record.destroy
    render json: { message: "Medical record deleted" }
  end

  private

  def authorize_admin
    unless @current_user.role == "admin"
      render json: { error: "Access denied: Admins only" }, status: :forbidden
    end
  end
end
