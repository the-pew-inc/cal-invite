# frozen_string_literal: true

# lib/cal_invite/providers.rb
module CalInvite
  module Providers
    SUPPORTED_PROVIDERS = %i[google ical outlook yahoo ics].freeze

    autoload :BaseProvider, 'cal_invite/providers/base_provider'
    autoload :Google, 'cal_invite/providers/google'
    autoload :Ical, 'cal_invite/providers/ical'
    autoload :Outlook, 'cal_invite/providers/outlook'
    autoload :Yahoo, 'cal_invite/providers/yahoo'
    autoload :Ics, 'cal_invite/providers/ics'
  end
end