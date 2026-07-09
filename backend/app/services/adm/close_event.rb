module Adm
  class CloseEvent
    def self.call(...) = new(...).call

    def initialize(**kargs)
      @event_id = kargs[:event_id]
    end

    def call
      event = Event.find_by(id: @event_id)
      return Result.new(status: 'error', errors: ['Evento inválido'], result_code: 404) if event.nil?

      if event.closed_at.present?
        return Result.new(status: 'error', errors: ['Evento já encerrado'], result_code: 409)
      end

      event.update!(closed_at: Time.current)
      Result.new(status: 'success', data: event, result_code: 200)
    end
  end
end
