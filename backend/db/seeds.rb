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

if admin_email.present? && admin_password.present?
  admin = AdminUser.find_or_initialize_by(email_address: admin_email)
  admin.password = admin_password
  admin.save!
  Rails.logger.info("[seeds] Admin user ready: #{admin.email_address}")
else
  Rails.logger.warn('[seeds] Skipping admin seed: set ADMIN_EMAIL and ADMIN_PASSWORD.')
end

# Provision the first paredão event and its contestants. Idempotent: the event
# is created only when no event exists yet, and participants are only created
# up to a total of 12 — re-running never produces duplicates.
EVENT_TITLE = 'Primeiro paredão do BBB 26 1/2'
PARTICIPANTS_TARGET = 12
EVENT_PARTCIPANTS = Adm::CreateEvent::PARTCIPANTS_RANGE.max

# Ensure the participant pool exists first, so the event can be created with
# its contestants already attached.
missing = PARTICIPANTS_TARGET - Partcipant.count
if missing.positive?
  missing.times do
    nickname = nil
    loop do
      nickname = Faker::Internet.unique.username(specifier: 5..12)
      break unless Partcipant.exists?(nickname: nickname)
    end
    Partcipant.create!(nickname: nickname, avatar: Partcipant::AVATARS.sample)
  end
  Rails.logger.info("[seeds] Created #{missing} participant(s); total is now #{Partcipant.count}.")
else
  Rails.logger.info("[seeds] Already have #{Partcipant.count} participant(s); skipping participant seed.")
end

# Create the event through Adm::CreateEvent so it is never persisted without
# contestants — the service enforces a valid number of participants.
if Event.exists?
  Rails.logger.info('[seeds] Event already present; skipping event seed.')
else
  partcipants = Partcipant.limit(EVENT_PARTCIPANTS).to_a
  result = Adm::CreateEvent.call(title: EVENT_TITLE, partcipants: partcipants)
  if result.status == 'success'
    Rails.logger.info("[seeds] Event ready: #{EVENT_TITLE}")
  else
    Rails.logger.error("[seeds] Failed to create event: #{result.errors.join(', ')}")
  end
end
