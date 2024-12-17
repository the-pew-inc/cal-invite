# frozen_string_literal: true

# lib/cal_invite/providers/ical.rb
module CalInvite
  module Providers
    class Ical < BaseProvider
      def generate
        [
          "BEGIN:VCALENDAR",
          "VERSION:2.0",
          "PRODID:-//CalInvite//EN",
          generate_events,
          "END:VCALENDAR"
        ].flatten.join("\r\n")
      end

      private

      def generate_events
        if event.multi_day_sessions.any?
          event.multi_day_sessions.map { |session| generate_vevent(session[:start_time], session[:end_time]) }
        else
          [generate_vevent(event.start_time, event.end_time)]
        end
      end

      def generate_vevent(start_time, end_time)
        vevent = [
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_time(Time.now)}",
          "DTSTART;TZID=#{event.timezone}:#{format_time(start_time)}",
          "DTEND;TZID=#{event.timezone}:#{format_time(end_time)}",
          "SUMMARY:#{event.title}",
          "DESCRIPTION:#{format_description}",
        ]

        if format_location
          vevent << "LOCATION:#{format_location}"
        end

        if event.url
          vevent << "URL:#{event.url}"
        end

        if attendees_list.any?
          attendees_list.each do |attendee|
            vevent << "ATTENDEE;RSVP=TRUE:mailto:#{attendee}"
          end
        end

        vevent << "END:VEVENT"
        vevent
      end

      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
      end

      def format_time(time)
        event.localize_time(time).strftime("%Y%m%dT%H%M%S")
      end

      def escape_text(text)
        text.to_s.gsub(/[,;\\]/) { |match| "\\#{match}" }
      end
    end
  end
end
