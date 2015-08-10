class OpenidConnect::OAuthAccessToken < ActiveRecord::Base
  belongs_to :authorization
  has_many :scopes, through: :scope_tokens

  before_validation :setup, on: :create

  validates :token, presence: true, uniqueness: true
  validates :authorization, presence: true

  scope :valid, ->(time) { where("expires_at >= ?", time) }

  def setup
    self.token = SecureRandom.hex(32)
    self.expires_at = 24.hours.from_now
  end

  def bearer_token
    @bearer_token ||= Rack::OAuth2::AccessToken::Bearer.new(
      access_token: token,
      expires_in: (expires_at - Time.now.utc).to_i
    )
  end

  def accessible?(_scopes_or_claims_=nil)
    true # TODO: For now don't support scopes
  end
end
