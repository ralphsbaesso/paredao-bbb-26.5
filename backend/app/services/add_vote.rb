class AddVote
  def self.call(...) = new(...).call

  def initialize(**kargs)
    @event_id = kargs[:event_id]
    @email = kargs[:email]
    @partcipant_id = kargs[:partcipant_id]
  end

  def call
    if invalid_email?(@email)
      return Result.new(status: 'error', errors: ['Email inválido'], result_code: 422)
    end

    Vote.create!(event_id: @event_id, email: @email, partcipant_id: @partcipant_id)
    Result.new(status: 'success', result_code: 201)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(status: 'error', errors: association_errors(e.record), result_code: 404)
  end

  private

  def invalid_email?(email)
    !email.to_s.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def association_errors(record)
    messages = []
    messages << 'Evento inválido' if record.errors.key?(:event)
    messages << 'Participante inválido' if record.errors.key?(:partcipant)
    messages
  end
end
