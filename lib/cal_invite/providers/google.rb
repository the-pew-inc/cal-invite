# frozen_string_literal: true

# lib/cal_invite/providers/google.rb
module CalInvite
  module Providers
    class Google < BaseProvider
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
          action: 'TEMPLATE',
          text: url_encode(event.title),
          dates: format_all_day_dates
        }

        add_optional_params(params)
        build_url(params)
      end

      def generate_single_event
        params = {
          action: 'TEMPLATE',
          text: url_encode(event.title),
          dates: format_dates
        }

        add_optional_params(params)
        build_url(params)
      end

      def format_all_day_dates
        # For all-day events, use current date if no start_time specified
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400) # Add one day if no end_time

        "#{start_date.strftime('%Y%m%d')}/#{end_date.strftime('%Y%m%d')}"
      end

      def format_dates
        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        start_time = event.start_time
        end_time = event.end_time

        "#{start_time.utc.strftime('%Y%m%dT%H%M%SZ')}/#{end_time.utc.strftime('%Y%m%dT%H%M%SZ')}"
      end

      def add_optional_params(params)
        description_parts = []
        description_parts << format_description if format_description
        description_parts << "Virtual Meeting URL: #{format_url}" if format_url
        params[:details] = url_encode(description_parts.join("\n\n")) if description_parts.any?

        params[:location] = url_encode(format_location) if format_location
        params
      end

      def build_url(params)
        query = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "https://calendar.google.com/calendar/render?#{query}"
      end
    end
  end
end
