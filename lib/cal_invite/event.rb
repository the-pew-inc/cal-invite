# frozen_string_literal: true

# lib/cal_invite/event.rb
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
                  :multi_day_sessions

    def initialize(attributes = {})
      @show_attendees = attributes.delete(:show_attendees) || false
      @timezone = attributes.delete(:timezone) || 'UTC'
      @multi_day_sessions = attributes.delete(:multi_day_sessions) || []

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def calendar_url(provider)
      provider_class = CalInvite::Providers.const_get(provider.to_s.camelize)
      generator = provider_class.new(self)
      generator.generate
    end

    # Convert a UTC time to event's timezone
    def localize_time(time)
      return time unless time
      time.in_time_zone(timezone)
    end

    # Get all event sessions (including multi-day)
    def sessions
      return [@start_time, @end_time] if multi_day_sessions.empty?

      multi_day_sessions.map do |session|
        [session[:start_time], session[:end_time]]
      end
    end
  end
end
