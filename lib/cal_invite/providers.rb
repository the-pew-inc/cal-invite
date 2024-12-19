# frozen_string_literal: true

require_relative 'providers/base_provider'

# lib/cal_invite/providers.rb
# Namespace module for all calendar providers supported by CalInvite.
# Each provider implements the interface defined by BaseProvider.
#
# @see CalInvite::Providers::BaseProvider
module CalInvite
  module Providers
    # List of supported calendar provider symbols
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
