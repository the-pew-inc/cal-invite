# frozen_string_literal: true

# lib/cal_invite/event.rb
module CalInvite
  # Represents a calendar event with its properties and validation rules
  class Event
    attr_accessor :title,
                  :start_time,
                  :end_time,
                  :description,
                  :location,
                  :url,
                  :attendees,
                  :timezone,
                  :show_attendees,
                  :notes,
                  :multi_day_sessions,
                  :all_day

    # Initialize a new Event instance
    #
    # @param attributes [Hash] The attributes to initialize the event with
    # @option attributes [String] :title The event title
    # @option attributes [Time] :start_time The event start time
    # @option attributes [Time] :end_time The event end time
    # @option attributes [String] :description The event description
    # @option attributes [String] :location The event location
    # @option attributes [String] :url The event URL
    # @option attributes [Array<String>] :attendees List of event attendees
    # @option attributes [String] :timezone The event timezone (default: 'UTC')
    # @option attributes [Boolean] :show_attendees Whether to show attendees (default: false)
    # @option attributes [String] :notes Additional notes for the event
    # @option attributes [Array<Hash>] :multi_day_sessions List of sessions for multi-day events
    # @option attributes [Boolean] :all_day Whether this is an all-day event (default: false)
    # @raise [ArgumentError] if required attributes are missing
    def initialize(attributes = {})
      @show_attendees = attributes.delete(:show_attendees) || false
      @timezone = attributes.delete(:timezone) || 'UTC'
      @multi_day_sessions = attributes.delete(:multi_day_sessions) || []
      @all_day = attributes.delete(:all_day) || false

      # Convert times to UTC before storing
      if attributes[:start_time]
        attributes[:start_time] = ensure_utc(attributes[:start_time])
      end
      if attributes[:end_time]
        attributes[:end_time] = ensure_utc(attributes[:end_time])
      end

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      validate!
    end

    # Generate a calendar URL for the specified provider
    #
    # @param provider [Symbol] The calendar provider to generate the URL for
    # @return [String] The generated calendar URL
    # @raise [ArgumentError] if required attributes are missing
    def calendar_url(provider)
      validate!
      provider_class = CalInvite::Providers.const_get(capitalize_provider(provider.to_s))
      generator = provider_class.new(self)
      generator.generate
    end

    # Convert a UTC time to event's timezone
    #
    # @param time [Time, nil] The time to convert
    # @return [Time, nil] The converted time in the event's timezone
    def localize_time(time)
      return time unless time
      # When timezone is UTC, we should preserve the UTC time
      # without any conversion
      return time if timezone == 'UTC'
      time.getlocal(timezone_offset)
    end

    # Get all event sessions including multi-day sessions
    #
    # @return [Array<Array<Time>>] Array of start and end time pairs
    def sessions
      return [@start_time, @end_time] if multi_day_sessions.empty?

      multi_day_sessions.map do |session|
        [session[:start_time], session[:end_time]]
      end
    end

    private

    def ensure_utc(time)
      return nil unless time
      time.is_a?(Time) ? time.utc : Time.parse(time.to_s).utc
    end

    def timezone_offset
      return '+00:00' if timezone == 'UTC'
      timezone # assume timezone is already in offset format
    end

    def capitalize_provider(string)
      # Handles both simple capitalization (ical -> Ical)
      # and compound names (office365 -> Office365)
      string.split('_').map(&:capitalize).join
    end

    # Validate the event attributes
    #
    # @raise [ArgumentError] if required attributes are missing
    def validate!
      raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

      unless all_day
        raise ArgumentError, "Start time is required for non-all-day events" if start_time.nil?
        raise ArgumentError, "End time is required for non-all-day events" if end_time.nil?
      end
    end
  end
end
