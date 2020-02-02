require 'test_helper'

class EventTest < ActiveSupport::TestCase

  def setup
    @opening_event     = Event.new kind: :opening, starts_at: DateTime.parse('2014-08-04 09:30'), ends_at: DateTime.parse('2014-08-04 12:30'), weekly_recurring: true
    @appointment_event = Event.new kind: :appointment, starts_at: DateTime.parse('2014-08-11 10:30'), ends_at: DateTime.parse('2014-08-11 11:30')
  end

  test 'valid event' do
    assert @opening_event.valid?
  end

  test 'invalid without starts_at' do
    @opening_event.starts_at = nil
    refute @opening_event.valid?
    assert_not_nil @opening_event.errors[:starts_at]
  end

  test 'invalid without ends_at' do
    @opening_event.ends_at = nil
    refute @opening_event.valid?
    assert_not_nil @opening_event.errors[:ends_at]
  end

  test 'invalid without kind' do
    @opening_event.kind = nil
    refute @opening_event.valid?
    assert_not_nil @opening_event.errors[:kind]
  end

  test '#ends_at_after_starts_at invalid with ends_at before or same as starts_at' do
    @opening_event.ends_at = @opening_event.starts_at - 2.days
    refute @opening_event.valid?
    assert @opening_event.errors[:ends_at].include?('must be after starts_at')

    @opening_event.ends_at = @opening_event.starts_at
    refute @opening_event.valid?
    assert @opening_event.errors[:ends_at].include?('must be after starts_at')
  end

  test '#half_hour_step_for_datetime' do
    @opening_event.starts_at = DateTime.parse('2014-08-04 09:15')
    @opening_event.ends_at   = DateTime.parse('2014-08-04 12:48')
    
    refute @opening_event.valid?
    assert @opening_event.errors[:starts_at].include?('minutes must be 00 or 30')
    assert @opening_event.errors[:ends_at].include?('minutes must be 00 or 30')
  end

  test '#available_opening invalid appointment without existed opening => weekly_recurring event' do
    opening_event = Event.new kind: :opening, starts_at: DateTime.parse('2014-08-04 09:30'), ends_at: DateTime.parse('2014-08-04 12:30'), weekly_recurring: true
    appointment_event1 = Event.new kind: :appointment, starts_at: DateTime.parse('2014-08-04 10:30'), ends_at: DateTime.parse('2014-08-04 11:30')
    appointment_event2 = Event.new kind: :appointment, starts_at: DateTime.parse('2014-08-11 10:30'), ends_at: DateTime.parse('2014-08-11 11:30')
    
    refute appointment_event1.valid?
    assert appointment_event1.errors[:base].include?('Must have opening events slots to create appointment.')
    refute appointment_event2.valid?
    assert appointment_event2.errors[:base].include?('Must have opening events slots to create appointment.')
    
    opening_event.save
    
    assert appointment_event1.valid?
    assert appointment_event2.valid?
  end

  test '#available_opening invalid appointment without existed opening => uniq event' do
    opening_event = Event.new kind: :opening, starts_at: DateTime.parse('2014-08-04 09:30'), ends_at: DateTime.parse('2014-08-04 12:30')
    appointment_event1 = Event.new kind: :appointment, starts_at: DateTime.parse('2014-08-04 10:30'), ends_at: DateTime.parse('2014-08-04 11:30')
    appointment_event2 = Event.new kind: :appointment, starts_at: DateTime.parse('2014-08-11 10:30'), ends_at: DateTime.parse('2014-08-11 11:30')
    
    refute appointment_event1.valid?
    assert appointment_event1.errors[:base].include?('Must have opening events slots to create appointment.')
    refute appointment_event2.valid?
    assert appointment_event2.errors[:base].include?('Must have opening events slots to create appointment.')
    
    opening_event.save
    
    assert appointment_event1.valid?
    refute appointment_event2.valid?
  end

  test '#repeating_event invalid too long event' do
    @opening_event.ends_at = @opening_event.starts_at + 1.week
    refute @opening_event.valid?
    assert @opening_event.errors[:base].include?('Cannot repeat event: The event is too long to repeat this often.')
  end

  test '#opening_slots return array of opening slots on specific date' do
    @opening_event.save

    opening_slots = Event.opening_slots @opening_event.starts_at
    assert_equal ['09:30', '10:00', '10:30', '11:00', '11:30', '12:00'], opening_slots
  end

  test '#appointment_slots return array of appointment slots on specific date' do
    @opening_event.save
    @appointment_event.save

    appointment_slots = Event.appointment_slots @appointment_event.starts_at
    assert_equal ['10:30', '11:00'], appointment_slots
  end

  test '#availabilities one simple test example' do
    @opening_event.save
    @appointment_event.save

    availabilities = Event.availabilities DateTime.parse('2014-08-10')
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ['09:30', '10:00', '11:30', '12:00'], availabilities[1][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

end
