# lib/calendar_invites.rb
require 'calendar_invites/version'
require 'calendar_invites/configuration'
require 'calendar_invites/event'
require 'calendar_invites/providers'
require 'calendar_invites/cache'
require 'calendar_invites/webhooks'
require 'calendar_invites/errors'

module CalendarInvites
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def reset_configuration!
      self.configuration = Configuration.new
    end
  end
end
