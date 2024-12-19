# frozen_string_literal: true

# lib/cal_invite/providers/ics_content.rb
module CalInvite
  module Providers
    # ICS content provider for generating calendar files in iCalendar format.
    # This provider focuses on generating standards-compliant ICS content
    # that can be used directly or wrapped for file download.
    #
    # @example Generate ICS content for a single event
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600
    #   )
    #   generator = CalInvite::Providers::IcsContent.new(event)
    #   ics_content = generator.generate
    #
    # @example Generate ICS content for a multi-day event
    #   event = CalInvite::Event.new(
    #     title: "Conference",
    #     multi_day_sessions: [
    #       { start_time: Time.parse("2024-04-01 09:00"), end_time: Time.parse("2024-04-01 17:00") },
    #       { start_time: Time.parse("2024-04-02 09:00"), end_time: Time.parse("2024-04-02 17:00") }
    #     ]
    #   )
    #   ics_content = CalInvite::Providers::IcsContent.new(event).generate
    class IcsContent < BaseProvider
      # Generates the complete ICS calendar content with all event details.
      # Handles both single events and multi-day sessions.
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

        if event.multi_day_sessions.any?
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

      # Generates a single VEVENT component with proper event properties.
      #
      # @param start_time [Time] The event start time
      # @param end_time [Time] The event end time
      # @return [Array<String>] Array of iCalendar format lines for the event
      def generate_vevent(start_time, end_time)
        [
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now.utc)}",
          "DTSTART:#{format_timestamp(start_time)}",
          "DTEND:#{format_timestamp(end_time)}",
          "SUMMARY:#{escape_text(event.title)}",
          description_line,
          location_line,
          url_line,
          attendee_lines,
          "END:VEVENT"
        ].compact
      end

      # Formats a time object as an UTC timestamp in iCalendar format.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted UTC timestamp (YYYYMMDDTHHmmSSZ)
      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
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

      # Generates the DESCRIPTION line if a description exists.
      #
      # @return [String, nil] The formatted DESCRIPTION line, or nil if no description
      def description_line
        return nil unless event.description
        "DESCRIPTION:#{escape_text(event.description)}"
      end

      # Generates the LOCATION line if a location exists.
      #
      # @return [String, nil] The formatted LOCATION line, or nil if no location
      def location_line
        return nil unless event.location
        "LOCATION:#{escape_text(event.location)}"
      end

      # Generates the URL line if a URL exists.
      #
      # @return [String, nil] The formatted URL line, or nil if no URL
      def url_line
        return nil unless event.url
        "URL:#{escape_text(event.url)}"
      end

      # Generates ATTENDEE lines for all attendees if showing attendees is enabled.
      #
      # @return [Array<String>, nil] Array of ATTENDEE lines, or nil if no attendees or not showing
      def attendee_lines
        return nil unless event.show_attendees && event.attendees&.any?
        event.attendees.map { |attendee| "ATTENDEE;RSVP=TRUE:mailto:#{attendee}" }
      end
    end

    # Module for handling ICS file downloads with proper headers and file naming.
    # Provides utility methods for preparing ICS content for HTTP download.
    module IcsDownload
      # Generates appropriate HTTP headers for ICS file download.
      #
      # @param filename [String] The desired filename for the download
      # @return [Hash] HTTP headers for the ICS file download
      def self.headers(filename)
        {
          'Content-Type' => 'text/calendar; charset=UTF-8',
          'Content-Disposition' => "attachment; filename=#{sanitize_filename(filename)}"
        }
      end

      # Sanitizes a filename by removing potentially problematic characters.
      #
      # @param filename [String] The filename to sanitize
      # @return [String] The sanitized filename
      def self.sanitize_filename(filename)
        filename.gsub(/[^0-9A-Za-z.\-]/, '_')
      end

      # Wraps ICS content with appropriate download information.
      #
      # @param content [String] The ICS calendar content
      # @param title [String] The event title to use in the filename
      # @return [Hash] Hash containing content and headers for download
      # @example
      #   result = IcsDownload.wrap_for_download(ics_content, "team-meeting")
      #   # => { content: "BEGIN:VCALENDAR...", headers: { 'Content-Type' => '...' } }
      def self.wrap_for_download(content, title)
        filename = sanitize_filename("#{title.downcase}_#{Time.now.strftime('%Y%m%d')}.ics")
        {
          content: content,
          headers: headers(filename)
        }
      end
    end

    # Compatibility class aliases
    # @api private
    class Ics < IcsContent; end
    # @api private
    class Ical < IcsContent; end
  end
end
