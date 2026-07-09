class VotesController < ApplicationController
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
end
