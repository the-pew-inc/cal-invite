# lib/cal_invite.rb
require 'securerandom'
require 'time'
require 'uri'

require 'cal_invite/version'
require 'cal_invite/configuration'
require 'cal_invite/event'
require 'cal_invite/providers'

module CalInvite
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
