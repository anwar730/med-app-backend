Rails.application.routes.draw do
  # ---------------------------
  # Authentication
  # ---------------------------
  post "/signup", to: "users#create"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Current logged-in user
  get "/me", to: "users#me"

  get "/admin/billings", to: "billings#all_billings"
  get "/admin/billings/stats", to: "billings#stats"  # Add this line


  resources :appointments do
  member do
    post :confirm
    post :start
    post :complete
    post :cancel
  end
end


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

   # Admin actions
  get "/admin/pending_doctors", to: "admin#pending_doctors"
  patch "/admin/approve_doctor/:id", to: "admin#approve_doctor"
  patch "/admin/reject_doctor/:id", to: "admin#reject_doctor"
  get "/admin/summary", to: "admin#summary"
  delete "/users/:id", to: "admins#destroy_user"

    # Appointments
  get "/appointments", to: "admins#appointments"
  delete "/appointments/:id", to: "admins#destroy_appointment"

    # Medical Records
  get "/medical_records", to: "admins#medical_records"
  delete "/medical_records/:id", to: "admins#destroy_medical_record"


  # ---------------------------
  # Billings & Stripe Payments
  # ---------------------------
  resources :billings, only: [:show, :update, :destroy] do
    member do
      post :create_checkout_session  # NEW: Create Stripe payment session
      get :verify_payment            # NEW: Verify payment status
    end
  end

  # ---------------------------
  # Stripe Webhook (for production)
  # ---------------------------
  post "/webhooks/stripe", to: "webhooks#stripe"  # NEW: Stripe webhook endpoint

  # For any unmatched routes# M-Pesa Routes
post 'billings/:id/mpesa_payment', to: 'mpesa_payments#create'
post 'mpesa/callback', to: 'mpesa_payments#callback'
  
  # Optional: Query payment status
get 'billings/:id/mpesa_status', to: 'mpesa_payments#status'
end
