# frozen_string_literal: true

# lib/cal_invite/providers/ical.rb
module CalInvite
  module Providers
    class Ical < BaseProvider
      BASE_URL = "webcal://calendar.apple.com"

      def generate
        params = {
          title: event.title,
          startdt: event.start_time.utc.strftime("%Y%m%dT%H%M%SZ"),
          enddt: (event.end_time || event.start_time + event.duration).utc.strftime("%Y%m%dT%H%M%SZ"),
          desc: event.description,
          location: event.location
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end
    end
  end
end
