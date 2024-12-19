# frozen_string_literal: true

# lib/cal_invite/providers/ical.rb
module CalInvite
  module Providers
    # iCalendar format provider for generating ICS (iCalendar) content.
    # This provider generates calendar content following the iCalendar specification (RFC 5545).
    # It supports single events, all-day events, and multi-day sessions with proper timezone handling.
    #
    # @example Creating a regular event
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600,
    #     timezone: 'America/New_York'
    #   )
    #   ical = CalInvite::Providers::Ical.new(event)
    #   ics_content = ical.generate
    #
    # @example Creating a multi-day event
    #   event = CalInvite::Event.new(
    #     title: "Conference",
    #     multi_day_sessions: [
    #       { start_time: Time.now, end_time: Time.now + 3600 },
    #       { start_time: Time.now + 86400, end_time: Time.now + 90000 }
    #     ]
    #   )
    #   ics_content = CalInvite::Providers::Ical.new(event).generate
    class Ical < BaseProvider
      # Generates an iCalendar format string containing the event details.
      # Includes proper calendar headers, timezone information (if needed),
      # and one or more event blocks.
      #
      # @return [String] The complete iCalendar format content
      def generate
        [
          "BEGIN:VCALENDAR",
          "VERSION:2.0",
          "PRODID:-//CalInvite//Ruby//EN",
          "CALSCALE:GREGORIAN",
          "METHOD:PUBLISH",
          generate_timezone,
          generate_events,
          "END:VCALENDAR"
        ].compact.join("\r\n")
      end

      private

      # Generates the event blocks (VEVENT) for the calendar.
      # Handles both single events and multi-day sessions.
      #
      # @return [String] The formatted event block(s)
      def generate_events
        if event.multi_day_sessions.any?
          event.multi_day_sessions.map { |session| generate_vevent(session) }.join("\r\n")
        else
          generate_vevent
        end
      end

      # Generates a single VEVENT block with all event details.
      # Handles both all-day events and time-specific events.
      #
      # @param session [Hash, nil] Optional session details for multi-day events
      # @return [String] The formatted VEVENT block
      # @raise [ArgumentError] If required time fields are missing for non-all-day events
      def generate_vevent(session = nil)
        lines = ["BEGIN:VEVENT"]

        if event.all_day
          start_date = event.start_time || Time.now
          end_date = event.end_time || (start_date + 86400)
          lines << "DTSTART;VALUE=DATE:#{format_date(start_date)}"
          lines << "DTEND;VALUE=DATE:#{format_date(end_date)}"
        else
          start_time = session ? session[:start_time] : event.start_time
          end_time = session ? session[:end_time] : event.end_time
          raise ArgumentError, "Start time is required for non-all-day events" unless start_time
          raise ArgumentError, "End time is required for non-all-day events" unless end_time
          lines << "DTSTART;TZID=#{event.timezone}:#{format_local_time(start_time)}"
          lines << "DTEND;TZID=#{event.timezone}:#{format_local_time(end_time)}"
        end

        # Required fields
        lines.concat([
          "SUMMARY:#{escape_text(event.title)}",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now.utc)}"
        ])

        # Optional fields
        lines << "DESCRIPTION:#{escape_text(format_description)}" if format_description
        lines << "LOCATION:#{escape_text(format_location)}" if format_location
        lines << "URL:#{escape_text(format_url)}" if format_url

        # Attendees
        if attendees = attendees_list
          attendees.each do |attendee|
            lines << "ATTENDEE;RSVP=TRUE:mailto:#{attendee}"
          end
        end

        lines << "END:VEVENT"
        lines.join("\r\n")
      end

      # Generates the timezone block (VTIMEZONE) for the calendar.
      # Only included for non-all-day events.
      #
      # @return [String, nil] The formatted timezone block, or nil for all-day events
      def generate_timezone
        return nil if event.all_day # No timezone needed for all-day events
        [
          "BEGIN:VTIMEZONE",
          "TZID:#{event.timezone}",
          "END:VTIMEZONE"
        ].join("\r\n")
      end

      # Generates a unique identifier for the calendar event.
      # Format: timestamp-randomhex@cal-invite
      #
      # @return [String] The generated UID
      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
      end

      # Formats a time object as a date string in iCalendar format.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted date (YYYYMMDD)
      def format_date(time)
        time.strftime("%Y%m%d")
      end

      # Formats a time object as a local time string in iCalendar format.
      # Times are assumed to be in the correct timezone already.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted local time (YYYYMMDDTHHmmSS)
      def format_local_time(time)
        time.strftime("%Y%m%dT%H%M%S")
      end

      # Formats a time object as an UTC timestamp in iCalendar format.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted UTC timestamp (YYYYMMDDTHHmmSSZ)
      def format_timestamp(time)
        time.strftime("%Y%m%dT%H%M%SZ")
      end

      # Escapes special characters in text according to iCalendar spec.
      # Handles backslashes, newlines, commas, and semicolons.
      #
      # @param text [String, nil] The text to escape
      # @return [String] The escaped text
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
