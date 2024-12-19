# frozen_string_literal: true

# lib/cal_invite/providers/ics.rb
module CalInvite
  module Providers
    # Generic ICS provider for generating standard iCalendar (.ics) files.
    # This provider generates ICS files that are compatible with most calendar applications.
    # Supports all-day events, regular events, and multi-day sessions with proper timezone handling.
    #
    # @example Creating a regular event ICS file
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600,
    #     timezone: 'America/New_York'
    #   )
    #   ics = CalInvite::Providers::Ics.new(event)
    #   ics_content = ics.generate
    #
    # @example Creating an all-day event ICS file
    #   event = CalInvite::Event.new(
    #     title: "Company Holiday",
    #     all_day: true,
    #     start_time: Date.today,
    #     end_time: Date.today + 1
    #   )
    #   ics_content = CalInvite::Providers::Ics.new(event).generate
    #
    # @example Creating a multi-day event ICS file
    #   event = CalInvite::Event.new(
    #     title: "Conference",
    #     multi_day_sessions: [
    #       { start_time: Time.parse("2024-04-01 09:00"), end_time: Time.parse("2024-04-01 17:00") },
    #       { start_time: Time.parse("2024-04-02 09:00"), end_time: Time.parse("2024-04-02 17:00") }
    #     ]
    #   )
    #   ics_content = CalInvite::Providers::Ics.new(event).generate
    class Ics < BaseProvider
      # Generates the complete ICS calendar content with proper calendar properties.
      # Handles all event types: all-day, regular, and multi-day sessions.
      #
      # @return [String] The complete ICS calendar content in iCalendar format
      def generate
        calendar_lines = [
          "BEGIN:VCALENDAR",
          "VERSION:2.0",
          "PRODID:-//CalInvite//EN",
          "CALSCALE:GREGORIAN",
          "METHOD:PUBLISH"
        ]

        if event.all_day
          calendar_lines.concat(generate_all_day_event)
        elsif event.multi_day_sessions.any?
          event.multi_day_sessions.each do |session|
            calendar_lines.concat(generate_vevent(session[:start_time], session[:end_time]))
          end
        else
          calendar_lines.concat(generate_vevent(event.start_time, event.end_time))
        end

        calendar_lines << "END:VCALENDAR"
        calendar_lines.join("\r\n")
      end

      private

      # Generates an all-day event component (VEVENT) with appropriate formatting.
      #
      # @return [Array<String>] Array of iCalendar format lines for the all-day event
      def generate_all_day_event
        vevent = [
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now.utc)}",
          "DTSTART;VALUE=DATE:#{format_date(event.start_time)}",
          "DTEND;VALUE=DATE:#{format_date(event.end_time)}",
          "SUMMARY:#{escape_text(event.title)}"
        ]
        add_optional_fields(vevent)
        vevent << "END:VEVENT"
        vevent
      end

      # Generates a regular or multi-day session event component (VEVENT).
      #
      # @param start_time [Time] The event start time
      # @param end_time [Time] The event end time
      # @return [Array<String>] Array of iCalendar format lines for the event
      def generate_vevent(start_time, end_time)
        vevent = [
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now.utc)}",
          "DTSTART;TZID=#{event.timezone}:#{format_local_timestamp(start_time)}",
          "DTEND;TZID=#{event.timezone}:#{format_local_timestamp(end_time)}",
          "SUMMARY:#{escape_text(event.title)}"
        ]
        add_optional_fields(vevent)
        vevent << "END:VEVENT"
        vevent
      end

      # Adds optional fields to the event component if they exist.
      # Handles description, location, URL, and attendees.
      #
      # @param vevent [Array<String>] The current event lines array
      # @return [void]
      def add_optional_fields(vevent)
        description_parts = []
        description_parts << format_description if format_description
        if description_parts.any?
          vevent << "DESCRIPTION:#{escape_text(description_parts.join('\n\n'))}"
        end

        if location = format_location
          vevent << "LOCATION:#{escape_text(location)}"
        end

        if url = format_url
          vevent << "URL:#{escape_text(url)}"
        end

        if attendees_list.any?
          attendees_list.each do |attendee|
            vevent << "ATTENDEE;RSVP=TRUE:mailto:#{attendee}"
          end
        end
      end

      # Formats a time object as an UTC timestamp in iCalendar format.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted UTC timestamp (YYYYMMDDTHHmmSSZ)
      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      # Formats a time object as a date string in iCalendar format.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted date (YYYYMMDD)
      def format_date(time)
        time.strftime("%Y%m%d")
      end

      # Formats a time object as a local timestamp in iCalendar format.
      # Note: Times are expected to be in UTC already.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted local time (YYYYMMDDTHHmmSS)
      def format_local_timestamp(time)
        time.strftime("%Y%m%dT%H%M%S")
      end

      # Generates a unique identifier for the calendar event.
      # Format: timestamp-randomhex@cal-invite
      #
      # @return [String] The generated UID
      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
      end

      # Escapes special characters in text according to iCalendar spec.
      #
      # @param text [String, nil] The text to escape
      # @return [String] The escaped text, or empty string if input was nil
      def escape_text(text)
        return '' if text.nil?
        text.to_s
            .gsub('\\', '\\\\')
            .gsub("\n", '\\n')
            .gsub(',', '\\,')
            .gsub(';', '\\;')
      end
    end
  end
end
