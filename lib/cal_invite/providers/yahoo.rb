# frozen_string_literal: true

# lib/cal_invite/providers/yahoo.rb
module CalInvite
  module Providers
    class Yahoo < BaseProvider
      BASE_URL = "https://calendar.yahoo.com"

      def generate
        if event.all_day
          generate_all_day_event
        elsif event.multi_day_sessions.any?
          generate_multi_day_event
        else
          generate_single_event
        end
      end

      private

      def generate_all_day_event
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400)

        params = {
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: format_date(start_date),
          et: format_date(end_date),
          desc: format_description,
          in_loc: format_location,
          crnd: event.timezone,
          allday: 'true'
        }

        "#{BASE_URL}/?#{URI.encode_www_form(params)}"
      end

      def generate_single_event
        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        params = {
          v: 60,
          view: 'd',
          type: 20,
          title: event.title,
          st: format_time(event.start_time),
          et: format_time(event.end_time),
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
            st: format_time(session[:start_time]),
            et: format_time(session[:end_time]),
            desc: format_description,
            in_loc: format_location,
            crnd: event.timezone
          }

          "#{BASE_URL}/?#{URI.encode_www_form(params)}"
        end

        sessions.join("\n")
      end

      def format_date(time)
        time.strftime("%Y%m%d")
      end

      def format_time(time)
        time.utc.strftime("%Y%m%dT%H%M%S")
      end
    end
  end
end
