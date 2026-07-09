class AddVote
  def self.call(...) = new(...).call

  def initialize(**kargs)
    @event_id = kargs[:event_id]
    @email = kargs[:email]
    @partcipant_id = kargs[:partcipant_id]
  end

  def call
    Rails.logger.debug(event: 'add_vote.start', event_id: @event_id, partcipant_id: @partcipant_id)

    if invalid_email?(@email)
      Rails.logger.warn(event: 'add_vote.invalid_email', reason: 'email inválido')
      return Result.new(status: 'error', errors: ['Email inválido'], result_code: 422)
    end

    Vote.create!(event_id: @event_id, email: @email, partcipant_id: @partcipant_id)

    Yabeda.paredao.votes_total.increment({ event: @event_id.to_s, participant: @partcipant_id.to_s })
    Rails.logger.info(event: 'add_vote.success', event_id: @event_id, partcipant_id: @partcipant_id)

    Result.new(status: 'success', result_code: 201)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn(event: 'add_vote.record_invalid', errors: e.record.errors.full_messages)
    Result.new(status: 'error', errors: association_errors(e.record), result_code: 404)
  rescue StandardError => e
    Rails.logger.error(event: 'add_vote.error', error_class: e.class.name, message: e.message)
    raise
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
