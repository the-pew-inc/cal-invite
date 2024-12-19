# frozen_string_literal: true
# lib/cal_invite/event.rb
require 'digest'

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

    def update_attributes(new_attributes)
      new_attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end

      invalidate_cache if caching_enabled?
      validate!
    end

    private

    def capitalize_provider(string)
      string.split('_').map(&:capitalize).join
    end

    def validate!
      raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

      unless all_day
        raise ArgumentError, "Start time is required for non-all-day events" if start_time.nil?
        raise ArgumentError, "End time is required for non-all-day events" if end_time.nil?
      end
    end

    def caching_enabled?
      CalInvite.configuration &&
        CalInvite.configuration.respond_to?(:cache_store) &&
        CalInvite.configuration.cache_store
    end

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

    def fetch_from_cache(key)
      return nil unless key && caching_enabled?
      CalInvite.configuration.cache_store.read(key)
    end

    def write_to_cache(key, value)
      return unless key && caching_enabled?

      expires_in = CalInvite.configuration&.cache_expires_in
      CalInvite.configuration.cache_store.write(
        key,
        value,
        expires_in: expires_in
      )
    end

    def invalidate_cache
      return unless caching_enabled?

      if CalInvite.configuration.cache_store.respond_to?(:delete_matched)
        CalInvite.configuration.cache_store.delete_matched("cal_invite:event:*")
      end
    end
  end
end
