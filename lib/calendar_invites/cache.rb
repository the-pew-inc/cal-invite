# lib/calendar_invites/cache.rb
module CalendarInvites
  class Cache
    class << self
      def fetch(key, &block)
        store.fetch(key, &block)
      end

      def delete(key)
        store.delete(key)
      end

      private

      def store
        @store ||= ActiveSupport::Cache.lookup_store(CalendarInvites.configuration.cache_store)
      end
    end
  end
end
