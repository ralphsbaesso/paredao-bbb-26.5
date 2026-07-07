module Admin
  # Sample protected administrative endpoint: returns the authenticated admin.
  # Also serves as a lightweight "is my token still valid?" check for the
  # frontend. Real management endpoints (paredões, participantes, relatórios)
  # will inherit from Admin::BaseController the same way.
  class ProfilesController < BaseController
    # GET /admin/profile
    def show
      render json: {
        id: Current.admin_user.id,
        email_address: Current.admin_user.email_address
      }
    end
  end
end
