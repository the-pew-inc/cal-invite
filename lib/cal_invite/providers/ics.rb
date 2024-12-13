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

        # Add events (either single or multiple sessions)
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

      def generate_vevent(start_time, end_time)
        vevent = [
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now)}",
          "DTSTART;TZID=#{event.timezone}:#{format_local_timestamp(start_time)}",
          "DTEND;TZID=#{event.timezone}:#{format_local_timestamp(end_time)}",
          "SUMMARY:#{escape_text(event.title)}"
        ]

        # Add description (including notes if present)
        if desc = format_description
          vevent << "DESCRIPTION:#{escape_text(desc)}"
        end

        # Add location and/or URL
        if event.location
          vevent << "LOCATION:#{escape_text(event.location)}"
        end

        if event.url
          vevent << "URL:#{escape_text(event.url)}"
        end

        # Add attendees if showing is enabled
        if attendees_list.any?
          attendees_list.each do |attendee|
            vevent << "ATTENDEE;RSVP=TRUE:mailto:#{attendee}"
          end
        end

        vevent << "END:VEVENT"
        vevent
      end

      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      def format_local_timestamp(time)
        event.localize_time(time).strftime("%Y%m%dT%H%M%S")
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
