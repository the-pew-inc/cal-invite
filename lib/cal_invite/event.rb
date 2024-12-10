# lib/calendar_invites/event.rb
module CalendarInvites
  class Event
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :title, :event_url, :address, :notes, :logo,
                 :start_date, :end_date, :duration, :timezone,
                 :organizer, :uid

    validates :title, :start_date, presence: true
    validates :timezone, presence: true, inclusion: { in: TZInfo::Timezone.all_identifiers }
    validate :end_date_or_duration_present

    def initialize(attributes = {})
      super
      @uid ||= SecureRandom.uuid
      @timezone ||= CalendarInvites.configuration.timezone
    end

    def calendar_file(provider)
      cache_key = "#{CalendarInvites.configuration.cache_prefix}/#{uid}/#{provider}"

      CalendarInvites::Cache.fetch(cache_key) do
        generator = CalendarInvites::Providers.const_get(provider.to_s.camelize).new(self)
        generator.generate
      end
    end

    def invalidate_cache!
      CalendarInvites::Providers::SUPPORTED_PROVIDERS.each do |provider|
        cache_key = "#{CalendarInvites.configuration.cache_prefix}/#{uid}/#{provider}"
        CalendarInvites::Cache.delete(cache_key)
      end
    end

    def update_attendees!
      CalendarInvites::Providers::SUPPORTED_PROVIDERS.each do |provider|
        provider_instance = CalendarInvites::Providers.const_get(provider.to_s.camelize).new(self)
        provider_instance.update_attendees
      end
      invalidate_cache!
    end

    private

    def end_date_or_duration_present
      errors.add(:base, 'Either end_date or duration must be present') unless end_date.present? || duration.present?
    end
  end
end
