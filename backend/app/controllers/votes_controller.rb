class VotesController < ApplicationController
  DEFAULT_LIMIT = 1
  DEFAULT_WINDOW_SECONDS = 1

  before_action :enforce_rate_limit, only: :create
  after_action :store_oring, only: :create

  def create
    result = AddVote.call(
      event_id: vote_params[:event_id],
      partcipant_id: vote_params[:partcipant_id],
      email: vote_params[:email]
    )

    if result.status == 'success'
      render json: { status: 'ok' }, status: result.result_code
    else
      render json: { errors: result.errors }, status: result.result_code
    end
  end

  private
    def vote_params
      params.permit(:event_id, :partcipant_id, :email)
    end

    def enforce_rate_limit
      return if load_test_bypass?

      origin = REDIS.get(request.remote_ip)
      return if origin.nil?

      Rails.logger.warn(
        event: 'vote.rate_limited',
        ip: request.remote_ip,
        event_id: vote_params[:event_id],
      )

      response.set_header('Retry-After', ENV['VOTE_RATE_LIMIT_WINDOW_SECONDS'] || DEFAULT_WINDOW_SECONDS)
      render json: { errors: ['Muitas requisições. Tente novamente em instantes.'] },
             status: :too_many_requests

    rescue => e
      Rails.logger.warn(e.message)
    end

    def load_test_bypass?
      header = request.headers['load-test']
      return false if header.blank?
      return false unless load_test_allowed?(header)

      Rails.logger.info(
        event: 'vote.load_test_bypass',
        ip: request.remote_ip,
        event_id: vote_params[:event_id]
      )
      true
    end

    def load_test_allowed?(header)
      token = ENV['LOAD_TEST_TOKEN']
      return ActiveSupport::SecurityUtils.secure_compare(header, token) if token.present?

      header.casecmp('true').zero?
    end

    def store_oring 
      expired = Integer(ENV.fetch('VOTE_RATE_LIMIT_RPS', DEFAULT_LIMIT)) * Integer(ENV.fetch('VOTE_RATE_LIMIT_WINDOW_SECONDS', DEFAULT_WINDOW_SECONDS))
      REDIS.set(request.remote_ip, 1, ex: expired)
    end
end
