Rails.application.routes.draw do
  # Administrative area — every route here requires an authenticated AdminUser
  # (token in the `Authorization: Bearer <token>` header), except login.
  namespace :admin do
    # POST /admin/session (login) and DELETE /admin/session (logout).
    resource :session, only: %i[create destroy]
    # GET /admin/profile — protected sample route / token validity check.
    resource :profile, only: :show
    resources :events, only: :create do
      member { patch :close }
    end
    resources :partcipants, only: %i[index show create]
  end

  # Public read surface for the voting UI (`/votacao`) — no token required.
  resources :events, only: %i[index show] do
    member { get :report }
  end

  resources :votes, only: :create

  mount Rswag::Ui::Engine => '/api-docs'

  mount Yabeda::Prometheus::Exporter => '/metrics', as: :metrics

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
