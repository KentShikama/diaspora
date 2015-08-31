class Token < ActiveRecord::Base
  belongs_to :o_auth_application

  before_validation :setup, on: :create

  validates :token, presence: true, uniqueness: true

  def setup
    self.token      = SecureRandom.hex(32)
    self.expires_at = 24.hours.from_now
  end

  def bearer_token
    @bearer_token ||= Rack::OAuth2::AccessToken::Bearer.new(
      access_token: token,
      expires_in: (expires_at - Time.now.utc).to_i
    )
  end
end
