# frozen_string_literal: true

# lib/cal_invite/event.rb
module CalInvite
  class Event
    attr_accessor :title, :start_time, :end_time, :description, :location, :url,
                  :attendees, :duration

    def initialize(attributes = {})
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def calendar_url(provider)
      provider_class = CalInvite::Providers.const_get(provider.to_s.camelize)
      generator = provider_class.new(self)
      generator.generate
    end

    private

    def end_date_or_duration_present
      end_time.present? || duration.present?
    end
  end
end
