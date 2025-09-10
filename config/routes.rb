Rails.application.routes.draw do
  # ---------------------------
  # Authentication
  # ---------------------------
  post "/signup", to: "users#create"
  post "/login", to: "sessions#create"

  # Current logged-in user
  get "/me", to: "users#me"

  # ---------------------------
  # Users
  # ---------------------------
  resources :users, only: [:index, :show, :update, :destroy]

  # ---------------------------
  # Appointments & Billings
  # ---------------------------
  resources :appointments do
    # Nested billings under appointments for create & index
    resources :billings, only: [:index, :create]
  end

  # Flat billing routes for show, update, destroy
  resources :billings, only: [:show, :update, :destroy]

  # ---------------------------
  # Medical Records & Prescriptions
  # ---------------------------
  resources :medical_records do
    # Nested prescriptions for index & create
    resources :prescriptions, only: [:index, :create]
  end

  # Flat prescription routes for show, update, destroy
  resources :prescriptions, only: [:show, :update, :destroy]
end
