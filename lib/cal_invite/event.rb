# frozen_string_literal: true

require 'digest'

# lib/cal_invite/event.rb
# Represents a calendar event with all its attributes and generation capabilities.
#
# @attr_accessor [String] title The title of the event
# @attr_accessor [Time] start_time The start time of the event
# @attr_accessor [Time] end_time The end time of the event
# @attr_accessor [String] description The description of the event
# @attr_accessor [String] location The location of the event
# @attr_accessor [String] url The URL associated with the event
# @attr_accessor [Array<String>] attendees The list of attendee email addresses
# @attr_accessor [String] timezone The timezone for the event
# @attr_accessor [Boolean] show_attendees Whether to include attendees in calendar invites
# @attr_accessor [String] notes Additional notes for the event
# @attr_accessor [Array<Hash>] multi_day_sessions Sessions for multi-day events
# @attr_accessor [Boolean] all_day Whether this is an all-day event
module CalInvite
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

    # Initializes a new Event instance with the given attributes.
    #
    # @param attributes [Hash] The attributes to initialize the event with
    # @option attributes [String] :title The event title
    # @option attributes [Time] :start_time The event start time
    # @option attributes [Time] :end_time The event end time
    # @option attributes [String] :description The event description
    # @option attributes [String] :location The event location
    # @option attributes [String] :url The event URL
    # @option attributes [Array<String>] :attendees The event attendees
    # @option attributes [String] :timezone ('UTC') The event timezone
    # @option attributes [Boolean] :show_attendees (false) Whether to show attendees
    # @option attributes [String] :notes Additional notes
    # @option attributes [Array<Hash>] :multi_day_sessions Multi-day session details
    # @option attributes [Boolean] :all_day (false) Whether it's an all-day event
    #
    # @raise [ArgumentError] If required attributes are missing
    def initialize(attributes = {})
      @show_attendees = attributes.delete(:show_attendees) || false
      @timezone = attributes.delete(:timezone) || 'UTC'
      @multi_day_sessions = attributes.delete(:multi_day_sessions) || []
      @all_day = attributes.delete(:all_day) || false

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      validate!
    end

    # Generates a calendar URL for the specified provider.
    #
    # @param provider [Symbol] The calendar provider to generate the URL for
    # @return [String] The generated calendar URL
    # @raise [ArgumentError] If required event attributes are missing
    #
    # @example Generate a Google Calendar URL
    #   event.generate_calendar_url(:google)
    #
    # @example Generate an Outlook Calendar URL
    #   event.generate_calendar_url(:outlook)
    def generate_calendar_url(provider)
      validate!

      if caching_enabled?
        cache_key = cache_key_for(provider)
        cached_url = fetch_from_cache(cache_key)
        return cached_url if cached_url
      end

      # Generate the URL
      provider_class = CalInvite::Providers.const_get(capitalize_provider(provider.to_s))
      generator = provider_class.new(self)
      url = generator.generate

      # Cache the result if caching is enabled
      write_to_cache(cache_key, url) if caching_enabled?

      url
    end

    # Updates the event attributes with new values.
    #
    # @param new_attributes [Hash] The new attributes to update
    # @return [void]
    # @raise [ArgumentError] If the updated attributes make the event invalid
    #
    # @example Update event title and time
    #   event.update_attributes(
    #     title: "Updated Meeting",
    #     start_time: Time.now + 3600
    #   )
    def update_attributes(new_attributes)
      new_attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      invalidate_cache if caching_enabled?
      validate!
    end

    private

    # Capitalizes each part of the provider name.
    #
    # @param string [String] The provider name to capitalize
    # @return [String] The capitalized provider name
    # @example
    #   capitalize_provider('google_calendar') # => "GoogleCalendar"
    def capitalize_provider(string)
      string.split('_').map(&:capitalize).join
    end

    # Validates the event attributes.
    #
    # @raise [ArgumentError] If required attributes are missing or invalid
    def validate!
      raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

      unless all_day
        raise ArgumentError, "Start time is required for non-all-day events" if start_time.nil?
        raise ArgumentError, "End time is required for non-all-day events" if end_time.nil?
      end
    end

    # Checks if caching is enabled in the configuration.
    #
    # @return [Boolean] true if caching is enabled, false otherwise
    def caching_enabled?
      CalInvite.configuration &&
        CalInvite.configuration.respond_to?(:cache_store) &&
        CalInvite.configuration.cache_store
    end

    # Generates a cache key for the event and provider combination.
    #
    # @param provider [Symbol] The calendar provider
    # @return [String, nil] The cache key or nil if caching is disabled
    def cache_key_for(provider)
      return nil unless caching_enabled?

      attributes_hash = Digest::MD5.hexdigest(
        [
          title,
          start_time&.to_i,
          end_time&.to_i,
          description,
          location,
          url,
          attendees,
          timezone,
          show_attendees,
          notes,
          multi_day_sessions,
          all_day,
          provider
        ].map(&:to_s).join('|')
      )

      "cal_invite:event:#{attributes_hash}"
    end

    # Retrieves a value from the cache store.
    #
    # @param key [String] The cache key
    # @return [String, nil] The cached value or nil if not found
    def fetch_from_cache(key)
      return nil unless key && caching_enabled?
      CalInvite.configuration.cache_store.read(key)
    end

    # Writes a value to the cache store.
    #
    # @param key [String] The cache key
    # @param value [String] The value to cache
    # @return [void]
    def write_to_cache(key, value)
      return unless key && caching_enabled?

      expires_in = CalInvite.configuration&.cache_expires_in
      CalInvite.configuration.cache_store.write(
        key,
        value,
        expires_in: expires_in
      )
    end

    # Invalidates all cached URLs for this event.
    #
    # @return [void]
    def invalidate_cache
      return unless caching_enabled?

      if CalInvite.configuration.cache_store.respond_to?(:delete_matched)
        CalInvite.configuration.cache_store.delete_matched("cal_invite:event:*")
      end
    end
  end
end
