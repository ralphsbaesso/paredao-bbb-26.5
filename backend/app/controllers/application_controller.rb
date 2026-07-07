class ApplicationController < ActionController::API
  # Public endpoints (voting, health check) inherit from here and stay open.
  # Admin-only endpoints inherit from Admin::BaseController, which requires
  # an authenticated AdminUser.
end
