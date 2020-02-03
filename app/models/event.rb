class Event < ActiveRecord::Base
  # ======= Enumerize =======
  enum kind: {
    opening: 0,
    appointment: 1,
  }

  # ======= Validations =======
  validates :starts_at, :ends_at, :kind, presence: true

  validate :ends_at_after_starts_at
  validate :half_hour_step_for_datetime
  validate :available_opening, if: :appointment?
  validate :repeating_event, if: :weekly_recurring?

  # ======= Scopes =======
  scope :recent,              -> { where('starts_at <= ?', 2.months.from_now) }
  scope :weekly_recurring,    -> { where(weekly_recurring: true) }
  scope :starts_at_asc,       -> { order(:starts_at) }
  scope :containing_date,     -> (date) { where('? BETWEEN DATE(starts_at) AND DATE(ends_at)', date.to_date) }
  scope :starts_at_wday_eq,   -> (date) { where("CAST(STRFTIME('%w', starts_at) AS INT) = ?", date.wday) }
  scope :starts_at_time_lteq, -> (date) { where("STRFTIME('%H:%M', starts_at) <= ?", date.strftime('%H:%M')) }
  scope :between_dates,       -> (left_date, right_date) {
    where(
      '(starts_at BETWEEN ? AND ?) OR (? BETWEEN starts_at AND ends_at)',
      left_date, right_date,
      left_date
    )
  }
  scope :for_next_x_months,   -> (nb_months) { between_dates(Time.now, (Time.now + nb_months.send(:month))) }

  # ======= Methods =======
  # Define methods to know event slots by kind
  [:opening, :appointment].each do |kind|
    define_singleton_method :"#{kind}_slots" do |date|
      unq_events  = Event.where(kind: kind).containing_date(date)
      rec_events  = Event.where(kind: kind).weekly_recurring.starts_at_wday_eq(date)
      events      = (unq_events + rec_events).uniq
      slots       = []

      events.each do |e|
        start_time  = e.starts_at.wday == date.wday ? e.starts_at : date.beginning_of_day
        end_time    = e.ends_at.wday == date.wday ? e.ends_at : e.starts_at.end_of_day

        while start_time < end_time do
          slots << start_time
          start_time += 30.minutes
        end
      end

      slots.map{ |s| s.strftime('%H:%M') }
    end
  end

  # Return a week slots availabilities by date
  def self.availabilities date
    date ||= Date.today
    res = []

    (date..(date + 6.days)).each do |d|
      opening_slots     = Event.opening_slots(d)
      appointment_slots = Event.appointment_slots(d)

      res << { date: d.to_date, slots: opening_slots - appointment_slots }
    end

    res
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? or starts_at.blank?
    errors.add(:ends_at, 'must be after starts_at') if ends_at <= starts_at
  end

  # Define slot's duration to 30 minutes
  def half_hour_step_for_datetime
    return if ends_at.blank? or starts_at.blank?
    errors.add(:starts_at, 'minutes must be 00 or 30') unless %w(00 30).include? starts_at.strftime('%M')
    errors.add(:ends_at, 'minutes must be 00 or 30') unless %w(00 30).include? ends_at.strftime('%M')
  end

  # Must have opening event to create appointment in it
  def available_opening
    return if ends_at.blank? or starts_at.blank?
    unq_events  = Event.opening.between_dates(starts_at, ends_at)
    rec_events  = Event.opening.weekly_recurring.starts_at_wday_eq(starts_at).starts_at_time_lteq(starts_at)
    res         = []

    (unq_events + rec_events).uniq.each { |e| res << e if (ends_at - starts_at) <= (e.ends_at - e.starts_at) }
    errors.add(:base, 'Must have opening events slots to create appointment.') if res.empty?
  end

  def repeating_event
    return if ends_at.blank? or starts_at.blank?
    errors.add(:base, 'Cannot repeat event: The event is too long to repeat this often.') if (ends_at.to_date - starts_at.to_date).to_i >= 7
  end

  # TODO : Manage overlaping event by type ?
  # TODO : Manage 2 consecutives opening events and 1 appointment overlaping both of opening event ?
end
