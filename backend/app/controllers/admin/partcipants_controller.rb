module Admin
  class PartcipantsController < BaseController
    def index
      render json: Partcipant.all
    end

    def show
      partcipant = Partcipant.find_by(id: params[:id])
      return render json: { errors: ['Participante inválido'] }, status: :not_found unless partcipant

      render json: partcipant
    end

    def create
      result = Adm::CreatePartcipant.call(**partcipant_params)
      render_result(result)
    end

    private
      def partcipant_params
        params.permit(:nickname, :avatar).to_h.symbolize_keys
      end

      def render_result(result)
        if result.status == 'success'
          render json: result.data, status: result.result_code
        else
          render json: { errors: result.errors }, status: result.result_code
        end
      end
  end
end
