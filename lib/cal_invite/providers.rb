# frozen_string_literal: true

# lib/cal_invite/providers.rb
require_relative 'providers/base_provider'

module CalInvite
  module Providers
    SUPPORTED_PROVIDERS = %i[google ical outlook yahoo ics office365].freeze

    autoload :Google, 'cal_invite/providers/google'
    autoload :Ical, 'cal_invite/providers/ical'
    autoload :Outlook, 'cal_invite/providers/outlook'
    autoload :Office365, 'cal_invite/providers/office365'
    autoload :Yahoo, 'cal_invite/providers/yahoo'
    autoload :IcsContent, 'cal_invite/providers/ics_content'
    autoload :IcsDownload, 'cal_invite/providers/ics_content'
    autoload :Ics, 'cal_invite/providers/ics'
  end
end
