# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Provision the first administrator. There is no public admin sign-up, so the
# initial AdminUser is created here (or via `bin/rails admin:create`).
#
# Credentials come from the environment — never hardcoded:
#   ADMIN_EMAIL / ADMIN_PASSWORD
# In development a convenience fallback is used so `bin/rails db:seed` just works.
admin_email = ENV['ADMIN_EMAIL']
admin_password = ENV['ADMIN_PASSWORD']

if admin_email.blank? && Rails.env.development?
  admin_email = 'admin@paredao.local'
  admin_password = 'password123'
  Rails.logger.info('[seeds] Using development admin fallback (admin@paredao.local).')
end

if admin_email.present? && admin_password.present?
  admin = AdminUser.find_or_initialize_by(email_address: admin_email)
  admin.password = admin_password
  admin.save!
  Rails.logger.info("[seeds] Admin user ready: #{admin.email_address}")
else
  Rails.logger.warn('[seeds] Skipping admin seed: set ADMIN_EMAIL and ADMIN_PASSWORD.')
end
