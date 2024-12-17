# frozen_string_literal: true

# lib/cal_invite/providers/google.rb
module CalInvite
  module Providers
    class Google < BaseProvider
      BASE_URL = "https://calendar.google.com/calendar/render"

      def generate
        if event.multi_day_sessions.any?
          generate_multi_day_event
        else
          generate_single_event
        end
      end

      private

      def generate_single_event
        params = {
          action: "TEMPLATE",
          text: event.title,
          dates: format_dates(event.start_time, event.end_time),
          details: format_description,
          location: format_location,
          ctz: event.timezone
        }

        if attendees_list.any?
          params[:add] = attendees_list.join(',')
        end

        "#{BASE_URL}?#{URI.encode_www_form(params)}"
      end

      def generate_multi_day_event
        # For multi-day events, Google Calendar supports recurring events
        sessions = event.multi_day_sessions.map do |session|
          format_dates(session[:start_time], session[:end_time])
        end

        params = {
          action: "TEMPLATE",
          text: event.title,
          dates: sessions.join(','),
          details: format_description,
          location: format_location,
          ctz: event.timezone
        }

        if attendees_list.any?
          params[:add] = attendees_list.join(',')
        end

        "#{BASE_URL}?#{URI.encode_www_form(params)}"
      end

      def format_dates(start_time, end_time)
        start_time = event.localize_time(start_time)
        end_time = event.localize_time(end_time)

        "#{start_time.strftime('%Y%m%dT%H%M%S')}/#{end_time.strftime('%Y%m%dT%H%M%S')}"
      end
    end
  end
end
