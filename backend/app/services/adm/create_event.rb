module Adm
  class CreateEvent
    PARTCIPANTS_RANGE = (2..4).freeze

    def self.call(...) = new(...).call

    def initialize(**kargs)
      @title = kargs[:title]
      @partcipants = kargs[:partcipants] || []
    end

    def call
      unless PARTCIPANTS_RANGE.include?(@partcipants.size)
        return Result.new(status: 'error', errors: ['Número de participantes inválido'], result_code: 422)
      end

      event = Event.create!(title: @title, partcipants: @partcipants)
      Result.new(status: 'success', data: event, result_code: 201)
    rescue ActiveRecord::RecordInvalid => e
      title_error(e.record)
    end

    private

    def title_error(record)
      details = record.errors.details[:title] || []
      if details.any? { |d| d[:error] == :taken }
        Result.new(status: 'error', errors: ['Título já existe'], result_code: 409)
      else
        Result.new(status: 'error', errors: ['Título inválido'], result_code: 422)
      end
    end
  end
end
