require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "get index" do
    get root_url

    assert_response :success
    assert_template :index
    assert_not_nil assigns(:event)
    assert_not_nil assigns(:recent_events)
    assert_not_nil assigns(:next_months_events)
  end

  test 'post create' do
    assert_difference('Event.count') do
      post events_url, params: { event: { kind: :opening, starts_at: DateTime.parse('2014-08-04 09:30'), ends_at: DateTime.parse('2014-08-04 12:30') } }
    end
    assert_redirected_to events_url
    assert_equal 'Event was successfully created.', flash[:notice]
    assert_template nil
    assert_not_nil assigns(:event)
    assert_not_nil assigns(:recent_events)
    assert_not_nil assigns(:next_months_events)
  end

  test 'get find_availabilities' do
    get find_availabilities_events_url

    assert_not_nil assigns(:event_date)
    assert_not_nil assigns(:availabilities)
  end
end