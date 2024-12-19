# frozen_string_literal: true

# lib/cal_invite/providers/yahoo.rb
module CalInvite
  module Providers
    # Yahoo Calendar provider for generating calendar event URLs.
    # This provider generates URLs that open the Yahoo Calendar with a pre-filled
    # event creation form. Supports all-day events, regular events, and multi-day
    # sessions with proper timezone handling.
    #
    # Note: Yahoo Calendar handles multi-day sessions differently from other providers,
    # generating separate event URLs for each session.
    #
    # @example Creating a regular event URL
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600,
    #     description: "Weekly team sync",
    #     timezone: "America/New_York"
    #   )
    #   yahoo = CalInvite::Providers::Yahoo.new(event)
    #   url = yahoo.generate
    #
    # @example Creating a multi-day event URL
    #   event = CalInvite::Event.new(
    #     title: "Conference",
    #     multi_day_sessions: [
    #       { start_time: Time.parse("2024-04-01 09:00"), end_time: Time.parse("2024-04-01 17:00") },
    #       { start_time: Time.parse("2024-04-02 09:00"), end_time: Time.parse("2024-04-02 17:00") }
    #     ]
    #   )
    #   urls = CalInvite::Providers::Yahoo.new(event).generate # Returns multiple URLs
    class Yahoo < BaseProvider
      # Base URL for Yahoo Calendar
      BASE_URL = "https://calendar.yahoo.com"

      # Generates Yahoo Calendar URL(s) for the event.
      # Handles all event types: all-day, regular, and multi-day sessions.
      #
      # @return [String] A single URL for regular or all-day events, or
      #   multiple URLs (separated by newlines) for multi-day sessions
      # @raise [ArgumentError] If required time fields are missing for non-all-day events
      def generate
        if event.all_day
          generate_all_day_event
        elsif event.multi_day_sessions.any?
          generate_multi_day_event
        else
          generate_single_event
        end
      end

      private

      # Generates a URL for an all-day event.
      # Uses simplified date format and sets the allday flag.
      #
      # @return [String] The Yahoo Calendar URL for an all-day event
      def generate_all_day_event
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400)

        params = {
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: format_date(start_date),
          et: format_date(end_date),
          desc: format_description,
          in_loc: format_location,
          crnd: event.timezone,
          allday: 'true'
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end

      # Generates a URL for a regular (time-specific) event.
      # Includes specific start and end times with timezone information.
      #
      # @return [String] The Yahoo Calendar URL for a regular event
      # @raise [ArgumentError] If start_time or end_time is missing
      def generate_single_event
        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        description_parts = []
        description_parts << format_description if format_description
        description_parts << "Virtual Meeting URL: #{format_url}" if format_url

        params = {
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: format_time(event.start_time),
          et: format_time(event.end_time),
          desc: description_parts.join("\n\n"),
          in_loc: format_location,
          crnd: event.timezone
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end

      # Generates multiple URLs for multi-day events, one for each session.
      # Yahoo Calendar doesn't support multiple sessions in a single URL.
      #
      # @return [String] Multiple Yahoo Calendar URLs, one per line
      def generate_multi_day_event
        sessions = event.multi_day_sessions.map do |session|
          params = {
            v: 60,
            view: 'd',
            type: 20,
            title: event.title,
            st: format_time(session[:start_time]),
            et: format_time(session[:end_time]),
            desc: format_description,
            in_loc: format_location,
            crnd: event.timezone
          }

          "#{BASE_URL}/?#{URI.encode_www_form(params)}"
        end

        sessions.join("\n")
      end

      # Formats a time object as a date string for Yahoo Calendar.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted date (YYYYMMDD)
      def format_date(time)
        time.strftime("%Y%m%d")
      end

      # Formats a time object as a UTC timestamp for Yahoo Calendar.
      # Yahoo Calendar accepts timezone separately in the crnd parameter.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted UTC time (YYYYMMDDTHHmmSSZ)
      def format_time(time)
        # Always use UTC format for the URL, timezone is passed separately
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end
    end
  end
end
