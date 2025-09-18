# app/controllers/users_controller.rb
class UsersController < ApplicationController
  include Rails.application.routes.url_helpers

  before_action :authorize_request, except: [:create]
  before_action :set_user, only: [:show, :update, :destroy]
  before_action :authorize_admin, only: [ :destroy]
  before_action :authorize_self_or_admin, only: [:show, :update]

  # Register user (patient or pending doctor)
  def create
  user = User.new(user_params)
  user.role ||= "patient"

  if user_params[:cv].present?
    user.cv.attach(user_params[:cv])  # ✅ attach CV properly
  end
  if user.save
    token = JsonWebToken.encode(user_id: user.id)
    render json: { 
      token: token, 
      user: user.as_json.merge({
        cv_url: user.cv.attached? ? url_for(user.cv) : nil
      }) 
    }, status: :created
  else
    render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
  end
end

  # List all users (admin only)
  def index
    render json: User.all
  end

  # Show profile
  def show
    render json: @user
  end

  # Update profile (self or admin)
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Delete user (admin only)
  def destroy
    @user.destroy
    render json: { message: "User deleted successfully" }
  end

  # Current logged in user
  def me
    render json: @current_user
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.permit(
    :name,
    :email,
    :password,
    :password_confirmation,
    :role,
    :phone,
    :gender,
    :dob,
    :specialization,
    :license_number,
    :workplace,
    :cv
  )
  end

  def authorize_admin
    render json: { error: "Admins only" }, status: :forbidden unless @current_user.role == "admin"
  end

  def authorize_self_or_admin
    unless @current_user == @user || @current_user.role == "admin"
      render json: { error: "Access denied" }, status: :forbidden
    end
  end
end
