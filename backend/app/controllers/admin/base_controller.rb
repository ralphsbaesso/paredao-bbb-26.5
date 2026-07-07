module Admin
  # Base for every administrative endpoint. Including Authentication enforces a
  # valid AdminUser session token on all actions; requests without one get 401.
  class BaseController < ApplicationController
    include Authentication
  end
end
