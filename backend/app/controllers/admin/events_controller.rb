module Admin
  class EventsController < BaseController
    def create
      result = Adm::CreateEvent.call(title: event_params[:title], partcipants: partcipants)
      render_result(result)
    end

    def close
      result = Adm::CloseEvent.call(event_id: params[:id])
      render_result(result)
    end

    private
      def event_params
        params.permit(:title, partcipant_ids: [])
      end

      def partcipants
        Partcipant.where(id: event_params[:partcipant_ids])
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
