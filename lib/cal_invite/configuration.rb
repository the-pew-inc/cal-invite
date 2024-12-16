# lib/cal_invite/configuration.rb
module CalInvites
  class Configuration
    attr_accessor :cache_store, :cache_prefix, :webhook_secret, :timezone

    def initialize
      @cache_store = :memory_store
      @cache_prefix = 'cal_invite'
      @webhook_secret = nil
      @timezone = 'UTC'
    end
  end
end
