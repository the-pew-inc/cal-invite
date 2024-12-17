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
          generate_events,
          "END:VCALENDAR"
        ].join("\n")
      end

      private

      def generate_events
        if event.multi_day_sessions.any?
          event.multi_day_sessions.map { |session| generate_vevent(session) }.join("\n")
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

          lines << "DTSTART:#{format_time(start_time)}"
          lines << "DTEND:#{format_time(end_time)}"
        end

        lines.concat([
          "SUMMARY:#{event.title}",
          "UID:#{generate_uid}"
        ])

        lines << "DESCRIPTION:#{format_description}" if format_description
        lines << "LOCATION:#{format_location}" if format_location

        if attendees = attendees_list
          attendees.each do |attendee|
            lines << "ATTENDEE:mailto:#{attendee}"
          end
        end

        lines << "END:VEVENT"
        lines.join("\n")
      end

      def generate_uid
        SecureRandom.uuid
      end

      def format_date(time)
        time.strftime("%Y%m%d")
      end

      def format_time(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end
    end
  end
end
