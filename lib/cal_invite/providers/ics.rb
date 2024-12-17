module CalInvite
  module Providers
    class Ics < BaseProvider
      def generate
        # Returns the actual .ics file content rather than a URL
        [
          "BEGIN:VCALENDAR",
          "VERSION:2.0",
          "PRODID:-//CalInvite//EN",
          "BEGIN:VEVENT",
          "UID:#{generate_uid}",
          "DTSTAMP:#{format_timestamp(Time.now)}",
          "DTSTART:#{format_timestamp(event.start_time)}",
          "DTEND:#{format_timestamp(event.end_time || event.start_time + event.duration)}",
          "SUMMARY:#{event.title}",
          "DESCRIPTION:#{event.description}",
          "LOCATION:#{event.location}",
          "END:VEVENT",
          "END:VCALENDAR"
        ].join("\r\n")
      end

      private

      def format_timestamp(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      def generate_uid
        "#{Time.now.to_i}-#{SecureRandom.hex(8)}@cal-invite"
      end
    end
  end
end
