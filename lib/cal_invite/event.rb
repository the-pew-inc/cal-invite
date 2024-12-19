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
      provider_class = CalInvite::Providers.const_get(capitalize_provider(provider.to_s))
      generator = provider_class.new(self)
      generator.generate
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
  end
end
