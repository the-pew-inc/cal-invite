# frozen_string_literal: true

# lib/cal_invite/providers/base_provider.rb
module CalInvite
  module Providers
    # Base class for calendar providers that implements common functionality
    # and defines the interface that all providers must implement
    class BaseProvider
      # @return [CalInvite::Event] The event being processed
      attr_reader :event

      # Initialize a new calendar provider
      #
      # @param event [CalInvite::Event] The event to generate a calendar URL for
      def initialize(event)
        @event = event
      end

      # Generate a calendar URL for the event
      # This method must be implemented by all provider subclasses
      #
      # @abstract
      # @raise [NotImplementedError] if the provider class doesn't implement this method
      def generate
        raise NotImplementedError, "#{self.class} must implement #generate"
      end

      protected

      # URL encode a string for use in calendar URLs
      #
      # @param str [#to_s] The string to encode
      # @return [String] The URL encoded string
      def url_encode(str)
        URI.encode_www_form_component(str.to_s)
      end

      # Format the event description including notes and URL if present
      #
      # @return [String, nil] The formatted description or nil if no content
      def format_description
        parts = []
        parts << event.description if event.description
        parts << "Notes: #{event.notes}" if event.notes
        parts << "URL: #{event.url}" if event.url
        parts.join("\n\n")
      end

      # Format the event location, combining physical location and URL if both present
      #
      # @return [String, nil] The formatted location or nil if neither location nor URL present
      def format_location
        return event.url if event.url && !event.location
        return event.location if event.location && !event.url
        return "#{event.location}\n#{event.url}" if event.location && event.url
        nil
      end

      # Get the list of attendees if showing attendees is enabled
      #
      # @return [Array<String>] The list of attendees or empty array if disabled/none present
      def attendees_list
        return [] unless event.show_attendees && event.attendees&.any?
        event.attendees
      end
    end
  end
end
