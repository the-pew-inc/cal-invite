# frozen_string_literal: true

# lib/cal_invite/providers/yahoo.rb
module CalInvite
  module Providers
    class Yahoo < BaseProvider
      BASE_URL = "https://calendar.yahoo.com"

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
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: format_start_time(event.start_time),
          et: format_end_time(event.end_time),
          desc: format_description,
          in_loc: format_location,
          crnd: event.timezone
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end

      def generate_multi_day_event
        # Yahoo doesn't support multi-day events in a single URL
        # Return multiple URLs, one for each session
        sessions = event.multi_day_sessions.map do |session|
          params = {
            v: 60,
            view: 'd',
            type: 20,
            title: event.title,
            st: format_start_time(session[:start_time]),
            et: format_end_time(session[:end_time]),
            desc: format_description,
            in_loc: format_location,
            crnd: event.timezone
          }

          "#{BASE_URL}/?#{URI.encode_www_form(params)}"
        end

        sessions.join("\n")
      end

      def format_start_time(time)
        event.localize_time(time).strftime("%Y%m%dT%H%M%S")
      end

      def format_end_time(time)
        event.localize_time(time).strftime("%Y%m%dT%H%M%S")
      end
    end
  end
end
