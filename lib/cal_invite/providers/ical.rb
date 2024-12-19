# frozen_string_literal: true

# lib/cal_invite/providers/ical.rb
module CalInvite
  module Providers
    class Ical < BaseProvider
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

      def generate_events
        if event.multi_day_sessions.any?
          event.multi_day_sessions.map { |session| generate_vevent(session) }.join("\r\n")
        else
          generate_vevent
        end
      end

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

      def generate_timezone
        return nil if event.all_day # No timezone needed for all-day events

        [
          "BEGIN:VTIMEZONE",
          "TZID:#{event.timezone}",
          "END:VTIMEZONE"
        ].join("\r\n")
      end

      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
      end

      def format_date(time)
        time.strftime("%Y%m%d")
      end

      def format_local_time(time)
        time.in_time_zone(event.timezone).strftime("%Y%m%dT%H%M%S")
      end

      def format_timestamp(time)
        time.strftime("%Y%m%dT%H%M%SZ")
      end

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
