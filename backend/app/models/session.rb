class Session < ApplicationRecord
  belongs_to :admin_user

  has_secure_token :token

  # Time-to-live for a session token, sourced from the environment so it is
  # never hardcoded. Defaults to 24 hours when unset.
  def self.ttl
    ENV.fetch('ADMIN_SESSION_TTL_HOURS', '24').to_i.hours
  end

  # Sessions still within their validity window (or with no expiry set).
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && expires_at.past?
  end
end
