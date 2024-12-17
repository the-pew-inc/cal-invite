# frozen_string_literal: true

# lib/cal_invite/providers/yahoo.rb
module CalInvite
  module Providers
    class Yahoo < BaseProvider
      BASE_URL = "https://calendar.yahoo.com"

      def generate
        params = {
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: event.start_time.utc.strftime("%Y%m%dT%H%M%SZ"),
          dur: format_duration,
          desc: event.description,
          in_loc: event.location
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end

      private

      def format_duration
        if event.duration
          (event.duration / 60).to_i # Convert seconds to minutes
        elsif event.end_time
          ((event.end_time - event.start_time) / 60).to_i
        else
          60 # Default to 1 hour
        end
      end
    end
  end
end
