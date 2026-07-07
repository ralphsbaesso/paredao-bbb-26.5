namespace :admin do
  desc 'Create or update an administrator. Usage: bin/rails admin:create EMAIL=you@example.com PASSWORD=secret'
  task create: :environment do
    email = ENV['EMAIL'].presence || abort('EMAIL is required')
    password = ENV['PASSWORD'].presence || abort('PASSWORD is required')

    admin = AdminUser.find_or_initialize_by(email_address: email)
    was_new = admin.new_record?
    admin.password = password
    admin.save!

    puts "Admin user #{was_new ? 'created' : 'updated'}: #{admin.email_address}"
  end
end
