# frozen_string_literal: true

# lib/cal_invite/providers/outlook.rb
module CalInvite
  module Providers
    class Outlook < BaseProvider
      def generate
        if event.all_day
          generate_all_day_event
        else
          generate_single_event
        end
      end

      private

      def generate_all_day_event
        params = {
          path: '/calendar/0/action/compose',
          subject: url_encode(event.title),
          allday: 'true'
        }

        # Use current date if no start_time specified
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400) # Add one day if no end_time

        params[:startdt] = format_date(start_date)
        params[:enddt] = format_date(end_date)

        add_optional_params(params)
        build_url(params)
      end

      def generate_single_event
        params = {
          path: '/calendar/0/action/compose',
          subject: url_encode(event.title)
        }

        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        params[:startdt] = format_time(event.start_time)
        params[:enddt] = format_time(event.end_time)

        add_optional_params(params)
        build_url(params)
      end

      def format_date(time)
        time.strftime('%Y-%m-%d')
      end

      def format_time(time)
        time.utc.strftime('%Y-%m-%dT%H:%M:%S')
      end

      def add_optional_params(params)
        params[:body] = url_encode(format_description) if format_description
        params[:location] = url_encode(format_location) if format_location

        if attendees = attendees_list
          params[:to] = url_encode(attendees.join(';'))
        end

        params
      end

      def build_url(params)
        query = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "https://outlook.live.com/calendar/0/action/compose?#{query}"
      end
    end
  end
end
