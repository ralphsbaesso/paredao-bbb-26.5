# Be sure to restart your server when you modify this file.

# Allow the decoupled frontend to call the API cross-origin. The allowed origin
# is injected at runtime (never hardcoded) and defaults to the local Nuxt dev
# server. Set FRONTEND_ORIGIN (comma-separated for multiple) in each environment.
#
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_ORIGIN', 'http://localhost:3000').split(',').map(&:strip)

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      # Expose the Authorization header so the frontend can read tokens if needed.
      expose: %w[Authorization]
  end
end
