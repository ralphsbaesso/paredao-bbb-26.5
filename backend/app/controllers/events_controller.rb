class EventsController < ApplicationController
  def index
    events = Event.includes(:partcipants).order(created_at: :desc, id: :desc)
    tallies = Vote.group(:event_id, :partcipant_id).count

    render json: events.map { |event| serialize_event(event, tally_for(event, tallies)) }
  end

  def show
    event = Event.includes(:partcipants).find_by(id: params[:id])
    return render json: { errors: ['Evento inválido'] }, status: :not_found if event.nil?

    render json: serialize_event(event, event.votes.group(:partcipant_id).count)
  end

  def report
    event = Event.includes(:partcipants).find_by(id: params[:id])
    return render json: { errors: ['Evento inválido'] }, status: :not_found if event.nil?

    counts = event.votes.group(:partcipant_id).count

    render json: {
      event_id: event.id,
      title: event.title,
      total_votes: counts.values.sum,
      per_partcipant: event.partcipants.map do |partcipant|
        { partcipant_id: partcipant.id, nickname: partcipant.nickname, count: counts.fetch(partcipant.id, 0) }
      end,
      per_hour: votes_per_hour(event)
    }
  end

  private
    def tally_for(event, tallies)
      event.partcipants.each_with_object({}) do |partcipant, acc|
        acc[partcipant.id] = tallies.fetch([event.id, partcipant.id], 0)
      end
    end

    def serialize_event(event, votes)
      {
        id: event.id,
        title: event.title,
        closed_at: event.closed_at,
        created_at: event.created_at,
        updated_at: event.updated_at,
        partcipants: event.partcipants.map { |partcipant| serialize_partcipant(partcipant) },
        votes: votes.transform_keys(&:to_s),
        total_votes: votes.values.sum
      }
    end

    def serialize_partcipant(partcipant)
      {
        id: partcipant.id,
        nickname: partcipant.nickname,
        avatar: partcipant.avatar,
        eliminated: partcipant.eliminated,
        created_at: partcipant.created_at,
        updated_at: partcipant.updated_at
      }
    end

    def votes_per_hour(event)
      event.votes
        .group(Arel.sql("date_trunc('hour', votes.created_at)"))
        .count
        .sort_by { |hour, _count| hour.to_s }
        .map { |hour, count| { hour: format_hour(hour), count: count } }
    end

    # date_trunc has no declared type; Active Record may return a Time or a string.
    def format_hour(hour)
      hour.respond_to?(:iso8601) ? hour.iso8601 : hour.to_s
    end
end
