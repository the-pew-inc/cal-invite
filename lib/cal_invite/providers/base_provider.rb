# frozen_string_literal: true

# lib/cal_invite/providers/base_provider.rb
module CalInvite
  module Providers
    class BaseProvider
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def generate
        raise NotImplementedError, "#{self.class} must implement #generate"
      end

      protected

      def url_encode(str)
        URI.encode_www_form_component(str.to_s)
      end

      def format_description
        parts = []
        parts << event.description if event.description
        parts << "Notes: #{event.notes}" if event.notes
        parts << "URL: #{event.url}" if event.url
        parts.join("\n\n")
      end

      def format_location
        return event.url if event.url && !event.location
        return event.location if event.location && !event.url
        return "#{event.location}\n#{event.url}" if event.location && event.url
        nil
      end

      def attendees_list
        return [] unless event.show_attendees && event.attendees&.any?
        event.attendees
      end
    end
  end
end
