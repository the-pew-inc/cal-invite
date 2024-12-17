# frozen_string_literal: true

# lib/cal_invite/providers/outlook.rb
module CalInvite
  module Providers
    class Outlook < BaseProvider
      BASE_URL = "https://outlook.live.com/calendar/0/deeplink/compose"

      def generate
        if event.multi_day_sessions.any?
          generate_multi_day_event
        else
          generate_single_event
        end
      end

      private

      def generate_single_event
        params = {
          subject: event.title,
          startdt: format_time(event.start_time),
          enddt: format_time(event.end_time),
          body: format_description,
          location: format_location,
          path: '/calendar/action/compose',
          rru: 'addevent'
        }

        if attendees_list.any?
          params[:to] = attendees_list.join(';')
        end

        "#{BASE_URL}?#{URI.encode_www_form(params)}"
      end

      def generate_multi_day_event
        # For Outlook, we create separate events for each session
        sessions = event.multi_day_sessions.map do |session|
          params = {
            subject: event.title,
            startdt: format_time(session[:start_time]),
            enddt: format_time(session[:end_time]),
            body: format_description,
            location: format_location,
            path: '/calendar/action/compose',
            rru: 'addevent'
          }

          if attendees_list.any?
            params[:to] = attendees_list.join(';')
          end

          "#{BASE_URL}?#{URI.encode_www_form(params)}"
        end

        sessions.join("\n")
      end

      def format_time(time)
        event.localize_time(time).strftime("%Y-%m-%dT%H:%M:%S")
      end
    end
  end
end
