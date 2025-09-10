class ApplicationController < ActionController::API
  before_action :authorize_request


  private

  def authorize_request
  header = request.headers["Authorization"]
  puts "AUTH HEADER: #{header.inspect}"  # Debug
  header = header.split(" ").last if header
  decoded = JsonWebToken.decode(header)
  puts "DECODED: #{decoded.inspect}"  # Debug
  @current_user = User.find(decoded[:user_id]) if decoded
rescue => e
  puts e.message  # Debug
  render json: { errors: ["Unauthorized"] }, status: :unauthorized
end

end
