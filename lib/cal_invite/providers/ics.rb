# frozen_string_literal: true

# lib/cal_invite/providers/ics.rb
module CalInvite
  module Providers
    class Ics < BaseProvider
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

      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      def format_date(time)
        time.strftime("%Y%m%d")
      end

      def format_local_timestamp(time)
        # All times are already in UTC, just format them
        time.strftime("%Y%m%dT%H%M%S")
      end

      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
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
