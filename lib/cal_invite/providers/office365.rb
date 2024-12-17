# frozen_string_literal: true

# lib/cal_invite/providers/office365.rb
module CalInvite
  module Providers
    class Office365 < BaseProvider
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
          subject: url_encode(event.title),
          path: '/calendar/action/compose',
          allday: 'true'
        }

        # Use current date if no start_time specified
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400) # Add one day if no end_time

        params[:startdt] = url_encode(format_date(start_date))
        params[:enddt] = url_encode(format_date(end_date))

        add_optional_params(params)
        build_url(params)
      end

      def generate_single_event
        params = {
          subject: url_encode(event.title),
          path: '/calendar/action/compose'
        }

        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        params[:startdt] = url_encode(format_time(event.start_time))
        params[:enddt] = url_encode(format_time(event.end_time))

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
        if description = format_description
          params[:body] = url_encode(description)
        end

        if location = format_location
          params[:location] = url_encode(location)
        end

        if attendees = attendees_list
          params[:to] = url_encode(attendees.join(';'))
        end

        params
      end

      def build_url(params)
        query = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "https://outlook.office.com/owa/?#{query}"
      end
    end
  end
end
