class Api::V1::MatrixController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  rescue_from Faraday::ConnectionFailed do |e|
    logger.warn "Attempted to connect to #{AppConfig.matrix.listener_url}. Error: #{e.message}."
    logger.warn e.backtrace[0, 10].join("\n")
  end

  def create
    conn = Faraday.new(url: AppConfig.matrix.listener_url)
    register_request_hash = { localpart: current_user.username, displayname: current_user.profile.full_name,
                              duration_seconds: 2.week.seconds.to_s, password_hash: current_user.encrypted_password }
    response = conn.post do |req|
      req.url "/_matrix/client/unstable/createUser?access_token=#{AppConfig.matrix.access_token}"
      req.headers["Content-Type"] = "application/json"
      req.body = register_request_hash.to_json
    end
    if response.status == 200
      render status: 200, json: response.body
    elsif
      logger.warn response.body
      render nothing: true, status: response.status
    end
  end
end
