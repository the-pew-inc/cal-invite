# frozen_string_literal: true

# lib/cal_invite/providers/outlook.rbw
module CalInvite
  module Providers
    class Outlook < BaseProvider
      BASE_URL = "https://outlook.live.com/calendar/0/deeplink/compose"

      def generate
        params = {
          subject: event.title,
          startdt: event.start_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          enddt: (event.end_time || event.start_time + event.duration).utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
          body: event.description,
          location: event.location,
          path: '/calendar/action/compose',
          rru: 'addevent'
        }

        # Add attendees if present
        if event.attendees&.any?
          params[:to] = event.attendees.join(';')
        end

        "#{BASE_URL}?#{URI.encode_www_form(params)}"
      end
    end
  end
end
