module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_admin_user

    def connect
      self.current_admin_user = find_verified_admin_user || reject_unauthorized_connection
    end

    private
      # Token-based auth for Action Cable, consistent with the HTTP API: the
      # client passes the session token as a query param (?token=...).
      def find_verified_admin_user
        Session.active.find_by(token: request.params[:token])&.admin_user
      end
  end
end
