# frozen_string_literal: true

# lib/cal_invite/providers/google.rb
module CalInvite
  module Providers
    class Google < BaseProvider
      BASE_URL = "https://calendar.google.com/calendar/render"

      def generate
        params = {
          action: "TEMPLATE",
          text: event.title,
          dates: format_dates,
          details: event.description,
          location: event.location
        }

        params[:add] = event.attendees.join(',') if event.attendees&.any?

        "#{BASE_URL}?#{URI.encode_www_form(params)}"
      end

      private

      def format_dates
        start_time = event.start_time.utc.strftime("%Y%m%dT%H%M%SZ")
        end_time = (event.end_time || event.start_time + event.duration).utc.strftime("%Y%m%dT%H%M%SZ")
        "#{start_time}/#{end_time}"
      end
    end
  end
end
