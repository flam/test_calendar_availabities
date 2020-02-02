class EventsController < ApplicationController
  before_action :events_list, only: [:index, :create]

  def index
    @event = Event.new
  end

  def create
    @event = Event.create(event_param)

    if @event.save
      redirect_to events_path, notice: "Event was successfully created."
    else
      render action: :index
    end
  end

  private

  def events_list
    @recent_events      = Event.recent.starts_at_asc
    @next_months_events = Event.for_next_x_months(2).starts_at_asc.group_by { |e| e.starts_at.strftime('%m/%Y') }
    # TODO : Manage weekly reccuring event by showing them on events list (=> not exist as event object)
  end

  def event_param
    params.require(:event).permit(:starts_at, :ends_at, :kind, :weekly_recurring)
  end
end
