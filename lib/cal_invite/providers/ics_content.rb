# lib/cal_invite/providers/ics_content.rb
module CalInvite
  module Providers
    class IcsContent < BaseProvider
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

      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
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

      def description_line
        return nil unless event.description
        "DESCRIPTION:#{escape_text(event.description)}"
      end

      def location_line
        return nil unless event.location
        "LOCATION:#{escape_text(event.location)}"
      end

      def url_line
        return nil unless event.url
        "URL:#{escape_text(event.url)}"
      end

      def attendee_lines
        return nil unless event.show_attendees && event.attendees&.any?
        event.attendees.map { |attendee| "ATTENDEE;RSVP=TRUE:mailto:#{attendee}" }
      end
    end

    # Optional download wrapper
    module IcsDownload
      def self.headers(filename)
        {
          'Content-Type' => 'text/calendar; charset=UTF-8',
          'Content-Disposition' => "attachment; filename=#{sanitize_filename(filename)}"
        }
      end

      def self.sanitize_filename(filename)
        filename.gsub(/[^0-9A-Za-z.\-]/, '_')
      end

      def self.wrap_for_download(content, title)
        filename = sanitize_filename("#{title.downcase}_#{Time.now.strftime('%Y%m%d')}.ics")
        {
          content: content,
          headers: headers(filename)
        }
      end
    end

    # For compatibility, keep the original classes but inherit from IcsContent
    class Ics < IcsContent
    end

    class Ical < IcsContent
    end
  end
end
