module Adm
  class CreatePartcipant
    def self.call(...) = new(...).call

    def initialize(**kargs)
      @nickname = kargs[:nickname]
      @avatar = kargs[:avatar]
    end

    def call
      partcipant = Partcipant.create!(nickname: @nickname, avatar: @avatar)
      Result.new(status: 'success', data: partcipant, result_code: 201)
    rescue ActiveRecord::RecordInvalid => e
      error_result(e.record)
    end

    private

    def error_result(record)
      details = record.errors.details[:nickname] || []
      if details.any? { |d| d[:error] == :taken }
        Result.new(status: 'error', errors: ['Apelido já existe'], result_code: 409)
      else
        Result.new(status: 'error', errors: ['Participante inválido'], result_code: 422)
      end
    end
  end
end
