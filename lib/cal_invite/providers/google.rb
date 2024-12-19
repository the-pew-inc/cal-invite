# frozen_string_literal: true

# lib/cal_invite/providers/google.rb
module CalInvite
  module Providers
    # Google Calendar provider for generating event URLs.
    # This provider generates URLs that open the Google Calendar event creation page
    # with pre-filled event details.
    #
    # @example Creating a regular event URL
    #   event = CalInvite::Event.new(
    #     title: "Team Meeting",
    #     start_time: Time.now,
    #     end_time: Time.now + 3600
    #   )
    #   google = CalInvite::Providers::Google.new(event)
    #   url = google.generate
    #
    # @example Creating an all-day event URL
    #   event = CalInvite::Event.new(
    #     title: "Company Holiday",
    #     all_day: true,
    #     start_time: Date.today,
    #     end_time: Date.today + 1
    #   )
    #   url = CalInvite::Providers::Google.new(event).generate
    class Google < BaseProvider
      # Generates a Google Calendar URL for the event.
      # Handles both regular and all-day events appropriately.
      #
      # @return [String] The generated Google Calendar URL
      # @see #generate_all_day_event
      # @see #generate_single_event
      def generate
        if event.all_day
          generate_all_day_event
        else
          generate_single_event
        end
      end

      private

      # Generates a URL for an all-day event.
      # Uses a simpler date format without time components.
      #
      # @return [String] The Google Calendar URL for an all-day event
      # @see #format_all_day_dates
      def generate_all_day_event
        params = {
          action: 'TEMPLATE',
          text: url_encode(event.title),
          dates: format_all_day_dates
        }
        add_optional_params(params)
        build_url(params)
      end

      # Generates a URL for a regular (time-specific) event.
      #
      # @return [String] The Google Calendar URL for a regular event
      # @raise [ArgumentError] If start_time or end_time is missing
      # @see #format_dates
      def generate_single_event
        params = {
          action: 'TEMPLATE',
          text: url_encode(event.title),
          dates: format_dates
        }
        add_optional_params(params)
        build_url(params)
      end

      # Formats dates for an all-day event according to Google Calendar's requirements.
      # If start_time is not specified, uses current date.
      # If end_time is not specified, adds one day to start_time.
      #
      # @return [String] Date range in format 'YYYYMMDD/YYYYMMDD'
      def format_all_day_dates
        start_date = event.start_time || Time.now
        end_date = event.end_time || (start_date + 86400) # Add one day if no end_time

        "#{start_date.strftime('%Y%m%d')}/#{end_date.strftime('%Y%m%d')}"
      end

      # Formats dates and times according to Google Calendar's requirements.
      # Times are converted to UTC and formatted appropriately.
      #
      # @return [String] Date/time range in format 'YYYYMMDDTHHmmSSZ/YYYYMMDDTHHmmSSZ'
      # @raise [ArgumentError] If either start_time or end_time is missing
      def format_dates
        raise ArgumentError, "Start time is required" unless event.start_time
        raise ArgumentError, "End time is required" unless event.end_time

        start_time = event.start_time
        end_time = event.end_time

        "#{start_time.utc.strftime('%Y%m%dT%H%M%SZ')}/#{end_time.utc.strftime('%Y%m%dT%H%M%SZ')}"
      end

      # Adds optional parameters to the URL parameters hash.
      # Handles description, virtual meeting URL, and location.
      #
      # @param params [Hash] The parameters hash to update
      # @return [Hash] The updated parameters hash with optional parameters added
      def add_optional_params(params)
        description_parts = []
        description_parts << format_description if format_description
        description_parts << "Virtual Meeting URL: #{format_url}" if format_url
        params[:details] = url_encode(description_parts.join("\n\n")) if description_parts.any?
        params[:location] = url_encode(format_location) if format_location
        params
      end

      # Builds the final Google Calendar URL from the parameters hash.
      #
      # @param params [Hash] The parameters to include in the URL
      # @return [String] The complete Google Calendar URL
      def build_url(params)
        query = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "https://calendar.google.com/calendar/render?#{query}"
      end
    end
  end
end
