module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_token
    end

    # Looks up an unexpired session from the Bearer token in the
    # `Authorization` header. Returns nil when the header is missing, malformed,
    # or the token is unknown/expired.
    def find_session_by_token
      token = bearer_token
      Session.active.find_by(token: token) if token.present?
    end

    def bearer_token
      pattern = /\ABearer /i
      header = request.authorization
      header.sub(pattern, '') if header&.match?(pattern)
    end

    # API-only: never redirect to a login screen — answer with 401 JSON.
    def request_authentication
      render json: { error: 'unauthorized' }, status: :unauthorized
    end

    def start_new_session_for(admin_user)
      admin_user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        expires_at: Session.ttl.from_now
      ).tap { |session| Current.session = session }
    end

    def terminate_session
      Current.session&.destroy
      Current.session = nil
    end
end
