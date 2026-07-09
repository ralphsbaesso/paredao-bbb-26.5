class AddVote
  def self.call(...) = new(...).call

  def initialize(event_id:, email:, partcipant_id:)
    @event_id = event_id
    @email = email
    @partcipant_id = partcipant_id
  end

  def call
    return Result.new(status: 'error') if invalid_email?(@email)

    Vote.create!(event_id: @event_id, email: @email, partcipant_id: @partcipant_id)
    Result.new(status: 'success')
  end

  private

  def invalid_email?(email)
    !email.match?(URI::MailTo::EMAIL_REGEXP)
  end
end
