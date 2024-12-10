# lib/calendar_invites/configuration.rb
module CalendarInvites
  class Configuration
    attr_accessor :cache_store, :cache_prefix, :webhook_secret, :timezone

    def initialize
      @cache_store = :memory_store
      @cache_prefix = 'calendar_invites'
      @webhook_secret = nil
      @timezone = 'UTC'
    end
  end
end
