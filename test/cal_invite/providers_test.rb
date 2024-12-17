# test/cal_invite/providers_test.rb
require 'test_helper'

module CalInvite
  class ProvidersTest < Minitest::Test
    def setup
      # Explicitly set UTC time using Time.utc to avoid timezone confusion
      @start_time = Time.utc(2024, 1, 1, 9, 0, 0)  # 9 AM UTC
      @end_time = Time.utc(2024, 1, 1, 10, 0, 0)   # 10 AM UTC
      @event = Event.new(
        title: "Test Meeting",
        start_time: @start_time,
        end_time: @end_time,
        description: "Test Description",
        location: "Test Location",
        url: "https://meet.test.com",
        attendees: ["test@example.com"],
        timezone: "UTC"
      )
    end

    def test_timezone_handling
      # Test with different timezone offset
      event = Event.new(
        title: "Test Meeting",
        start_time: Time.new(2024, 1, 1, 9, 0, 0, "+00:00"),
        end_time: Time.new(2024, 1, 1, 10, 0, 0, "+00:00"),
        timezone: "+01:00"
      )

      url = event.calendar_url(:google)
      # Google Calendar expects UTC times
      assert_match %r{dates=20240101T090000Z/20240101T100000Z}, url
    end

    def test_google_calendar_url
      url = @event.calendar_url(:google)
      assert_match %r{^https://calendar\.google\.com/calendar/render\?action=TEMPLATE}, url
      assert_match %r{&text=Test\+Meeting}, url
      assert_match %r{&dates=20240101T090000Z/20240101T100000Z}, url
      assert_match %r{&location=Test\+Location}, url
    end

    def test_outlook_calendar_url
      url = @event.calendar_url(:outlook)
      assert_match %r{^https://outlook\.live\.com/calendar/0/action/compose}, url
      assert_match %r{&subject=Test\+Meeting}, url
      assert_match %r{&startdt=2024-01-01T09:00:00}, url
      assert_match %r{&enddt=2024-01-01T10:00:00}, url
    end

    def test_office365_calendar_url
      url = @event.calendar_url(:office365)
      assert_match %r{^https://outlook\.office\.com/owa/\?}, url
      assert_match %r{subject=Test\+Meeting}, url  # Removed the & prefix since it could be anywhere in the query string
      assert_match %r{startdt=2024-01-01T09%3A00%3A00}, url
      assert_match %r{enddt=2024-01-01T10%3A00%3A00}, url
      # Optional but recommended assertions
      assert_match %r{path=/calendar/action/compose}, url
      assert_match %r{body=}, url
      assert_match %r{location=}, url
    end

    def test_yahoo_calendar_url
      url = @event.calendar_url(:yahoo)
      assert_match %r{^https://calendar\.yahoo\.com/}, url
      assert_match %r{&title=Test\+Meeting}, url
      assert_match %r{&st=20240101T090000}, url
      assert_match %r{&et=20240101T100000}, url
    end

    def test_ical_calendar_url
      url = @event.calendar_url(:ical)
      assert_match /BEGIN:VCALENDAR/, url
      assert_match /DTSTART:20240101T090000Z/, url
      assert_match /DTEND:20240101T100000Z/, url
      assert_match /SUMMARY:Test Meeting/, url
    end

    def test_url_encoding_special_characters
      event = Event.new(
        title: "Test & Meeting + Spaces",
        start_time: @start_time,
        end_time: @end_time,
        location: "Location & More",
        timezone: "UTC"
      )

      url = event.calendar_url(:google)
      assert_match %r{text=Test\+%26\+Meeting\+%2B\+Spaces}, url
      assert_match %r{location=Location\+%26\+More}, url
    end

    def test_all_day_event_formatting
      event = Event.new(
        title: "All Day Event",
        all_day: true
      )

      # Test Google calendar formatting
      google_url = event.calendar_url(:google)
      today = Time.now.strftime('%Y%m%d')
      tomorrow = (Time.now + 86400).strftime('%Y%m%d')
      assert_match %r{dates=#{today}/#{tomorrow}}, google_url

      # Test other providers
      [:outlook, :office365, :yahoo, :ical].each do |provider|
        url = event.calendar_url(provider)
        assert url, "URL should be generated for #{provider} with all-day event"
      end
    end

    def test_all_day_event_with_specific_dates
      event = Event.new(
        title: "All Day Event",
        all_day: true,
        start_time: Time.new(2024, 1, 1),
        end_time: Time.new(2024, 1, 2)
      )

      url = event.calendar_url(:google)
      assert_match %r{dates=20240101/20240102}, url
    end
  end
end
