module Admin
  # Login/logout for administrators. Responds only in JSON.
  class SessionsController < BaseController
    allow_unauthenticated_access only: :create
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { render json: { error: 'rate_limited' }, status: :too_many_requests }

    # POST /admin/session — authenticate and issue a session token.
    def create
      admin_user = AdminUser.authenticate_by(params.permit(:email_address, :password))

      if admin_user
        start_new_session_for(admin_user)
        render json: session_payload(Current.session), status: :created
      else
        render json: { error: 'invalid_credentials' }, status: :unauthorized
      end
    end

    # DELETE /admin/session — invalidate the current token.
    def destroy
      terminate_session
      head :no_content
    end

    private
      def session_payload(session)
        {
          token: session.token,
          expires_at: session.expires_at,
          admin_user: admin_user_payload(session.admin_user)
        }
      end

      def admin_user_payload(admin_user)
        { id: admin_user.id, email_address: admin_user.email_address }
      end
  end
end
