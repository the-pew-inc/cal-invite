# frozen_string_literal: true

# lib/cal_invite/providers/office365.rb
module CalInvite
  module Providers
    # Microsoft Office 365 provider for generating calendar event URLs.
    # This provider generates URLs that open the Office 365 web calendar
    # with a pre-filled event creation form. Supports both all-day and
    # time-specific events with proper timezone handling.
    #
    # @example Creating a regular event URL
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600,
    #     description: "Weekly team sync"
    #   )
    #   office365 = CalInvite::Providers::Office365.new(event)
    #   url = office365.generate
    #
    # @example Creating an all-day event URL with attendees
    #   event = CalInvite::Event.new(
    #     title: "Company Off-Site",
    #     all_day: true,
    #     start_time: Date.today,
    #     end_time: Date.today + 1,
    #     attendees: ["john@example.com", "jane@example.com"],
    #     show_attendees: true
    #   )
    #   url = CalInvite::Providers::Office365.new(event).generate
    class Office365 < BaseProvider
      # Generates an Office 365 calendar URL for the event.
      # Automatically handles both all-day and time-specific events.
      #
      # @return [String] The Office 365 calendar URL
      # @raise [ArgumentError] If required time fields are missing for non-all-day events
      def generate
        if event.all_day
          generate_all_day_event
        else
          generate_single_event
        end
      end

      private

      # Generates a URL for an all-day event.
      # Uses simplified date format and sets the allday flag.
      #
      # @return [String] The Office 365 calendar URL for an all-day event
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

      # Generates a URL for a regular (time-specific) event.
      # Includes specific start and end times in UTC format.
      #
      # @return [String] The Office 365 calendar URL for a regular event
      # @raise [ArgumentError] If start_time or end_time is missing
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

      # Formats a time object as a date string for Office 365.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted date (YYYY-MM-DD)
      def format_date(time)
        time.strftime('%Y-%m-%d')
      end

      # Formats a time object as a UTC timestamp for Office 365.
      # Office 365 handles timezone conversion on their end.
      #
      # @param time [Time] The time to format
      # @return [String] The formatted UTC time (YYYY-MM-DDThh:mm:ssZ)
      def format_time(time)
        # Always use UTC format, timezone is handled by the calendar
        time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      # Adds optional parameters to the URL parameters hash.
      # Handles description, virtual meeting URL, location, and attendees.
      #
      # @param params [Hash] The parameters hash to update
      # @return [Hash] The updated parameters hash
      def add_optional_params(params)
        description_parts = []
        description_parts << format_description if format_description
        description_parts << "Virtual Meeting URL: #{format_url}" if format_url
        params[:body] = url_encode(description_parts.join("\n\n")) if description_parts.any?
        params[:location] = url_encode(format_location) if format_location

        if attendees = attendees_list
          params[:to] = url_encode(attendees.join(';'))
        end

        params
      end

      # Builds the final Office 365 calendar URL.
      #
      # @param params [Hash] The parameters to include in the URL
      # @return [String] The complete Office 365 calendar URL
      def build_url(params)
        query = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "https://outlook.office.com/owa/?#{query}"
      end
    end
  end
end
