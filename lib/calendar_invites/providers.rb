# lib/calendar_invites/providers.rb
module CalendarInvites
  module Providers
    SUPPORTED_PROVIDERS = [:google, :ical, :outlook, :yahoo, :ics]

    autoload :BaseProvider, 'calendar_invites/providers/base_provider'
    autoload :Google, 'calendar_invites/providers/google'
    autoload :Ical, 'calendar_invites/providers/ical'
    autoload :Outlook, 'calendar_invites/providers/outlook'
    autoload :Yahoo, 'calendar_invites/providers/yahoo'
    autoload :Ics, 'calendar_invites/providers/ics'
  end
end
