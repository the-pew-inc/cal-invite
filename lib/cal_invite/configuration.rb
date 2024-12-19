# frozen_string_literal: true

# lib/cal_invite/configuration.rb
module CalInvite
  class Configuration
    attr_reader :cache_store, :cache_prefix, :cache_expires_in, :webhook_secret, :timezone

    def initialize
      @cache_store = nil
      @cache_prefix = 'cal_invite'
      @cache_expires_in = 24.hours # now this will work with active_support loaded
      @webhook_secret = nil
      @timezone = 'UTC'
    end

    def cache_store=(store)
      @cache_store = case store
      when :memory_store
        ActiveSupport::Cache::MemoryStore.new
      when :null_store
        ActiveSupport::Cache::NullStore.new
      when Symbol
        raise ArgumentError, "Unsupported cache store: #{store}"
      else
        # Allow custom cache store objects that respond to read/write/delete
        unless store.respond_to?(:read) && store.respond_to?(:write) && store.respond_to?(:delete)
          raise ArgumentError, "Custom cache store must implement read/write/delete methods"
        end
        store
      end
    end

    def cache_prefix=(prefix)
      @cache_prefix = prefix.to_s
    end

    def cache_expires_in=(duration)
      @cache_expires_in = duration.to_i
    end

    def webhook_secret=(secret)
      @webhook_secret = secret
    end

    def timezone=(tz)
      @timezone = tz.to_s
    end
  end
end
