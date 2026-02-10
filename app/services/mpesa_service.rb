# app/services/mpesa_service.rb
require 'net/http'
require 'json'
require 'base64'

class MpesaService
  # Daraja API credentials (store these in Rails credentials or ENV)
  CONSUMER_KEY = ENV['MPESA_CONSUMER_KEY']
  CONSUMER_SECRET = ENV['MPESA_CONSUMER_SECRET']
  SHORTCODE = ENV['MPESA_SHORTCODE'] # Your paybill/till number
  PASSKEY = ENV['MPESA_PASSKEY']
  CALLBACK_URL = ENV['MPESA_CALLBACK_URL'] # e.g., https://yourdomain.com/mpesa/callback
  
  # Use sandbox for testing, production for live
  BASE_URL = Rails.env.production? ? 
    'https://api.safaricom.co.ke' : 
    'https://sandbox.safaricom.co.ke'

  class << self
    # Get OAuth access token
    def get_access_token
      url = URI("#{BASE_URL}/oauth/v1/generate?grant_type=client_credentials")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(url)
      credentials = Base64.strict_encode64("#{CONSUMER_KEY}:#{CONSUMER_SECRET}")
      request['Authorization'] = "Basic #{credentials}"
      
      response = http.request(request)
      data = JSON.parse(response.body)
      
      data['access_token']
    rescue => e
      Rails.logger.error "M-Pesa token error: #{e.message}"
      nil
    end

    # Initiate STK Push (Lipa Na M-Pesa Online)
    def stk_push(phone_number:, amount:, account_reference:, transaction_desc:)
      Rails.logger.info "=== Getting M-Pesa Access Token ==="
      access_token = get_access_token
      
      unless access_token
        Rails.logger.error "Failed to get M-Pesa access token"
        return { success: false, error: 'Failed to get access token' }
      end
      
      Rails.logger.info "Access token obtained successfully"

      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      password = Base64.strict_encode64("#{SHORTCODE}#{PASSKEY}#{timestamp}")

      url = URI("#{BASE_URL}/mpesa/stkpush/v1/processrequest")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      
      request.body = {
        BusinessShortCode: SHORTCODE,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline', # or 'CustomerBuyGoodsOnline' for till
        Amount: amount.to_i,
        PartyA: phone_number,
        PartyB: SHORTCODE,
        PhoneNumber: phone_number,
        CallBackURL: CALLBACK_URL,
        AccountReference: account_reference,
        TransactionDesc: transaction_desc
      }.to_json

      Rails.logger.info "=== M-Pesa STK Push Request ==="
      Rails.logger.info "URL: #{url}"
      Rails.logger.info "Body: #{request.body}"

      response = http.request(request)
      
      Rails.logger.info "=== M-Pesa STK Push Response ==="
      Rails.logger.info "Status: #{response.code}"
      Rails.logger.info "Body: #{response.body}"
      
      data = JSON.parse(response.body)

      if data['ResponseCode'] == '0'
        {
          success: true,
          checkout_request_id: data['CheckoutRequestID'],
          merchant_request_id: data['MerchantRequestID'],
          response_description: data['ResponseDescription']
        }
      else
        {
          success: false,
          error: data['errorMessage'] || data['ResponseDescription']
        }
      end
    rescue => e
      Rails.logger.error "M-Pesa STK Push error: #{e.message}"
      { success: false, error: e.message }
    end

    # Query STK Push status (optional - for checking payment status)
    def query_stk_status(checkout_request_id:)
      access_token = get_access_token
      return { success: false, error: 'Failed to get access token' } unless access_token

      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      password = Base64.strict_encode64("#{SHORTCODE}#{PASSKEY}#{timestamp}")

      url = URI("#{BASE_URL}/mpesa/stkpushquery/v1/query")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'
      
      request.body = {
        BusinessShortCode: SHORTCODE,
        Password: password,
        Timestamp: timestamp,
        CheckoutRequestID: checkout_request_id
      }.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "M-Pesa query error: #{e.message}"
      { success: false, error: e.message }
    end
  end
end