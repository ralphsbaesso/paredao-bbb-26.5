# Be sure to restart your server when you modify this file.

# Allow the decoupled frontend to call the API cross-origin. Origins are open to
# any host so the API can be consumed from anywhere.
#
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      # Expose the Authorization header so the frontend can read tokens if needed.
      expose: %w[Authorization]
  end
end
