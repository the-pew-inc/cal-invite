# frozen_string_literal: true

# app/lib/base_provider.rb
# Base class for calendar providers that implements common functionality
# and defines the interface that all providers must implement.
#
# @abstract Subclass and override {#generate} to implement a calendar provider
class BaseProvider
  attr_reader :event

  # Initialize a new calendar provider
  #
  # @param event [CalInvite::Event] The event to generate a calendar URL for
  def initialize(event)
    @event = event
  end

  # Generate a calendar URL or content for the event.
  # This method must be implemented by all provider subclasses.
  #
  # @abstract
  # @return [String] The generated calendar URL or content
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

  # Format the event description
  # @return [String, nil] The formatted description or nil if no content
  def format_description
    parts = []
    parts << event.description if event.description
    parts << "Notes: #{event.notes}" if event.notes
    parts.join("\n\n")
  end

  # Get just the physical location
  # @return [String, nil] The location or nil if not present
  def format_location
    event.location
  end

  # Get the URL for virtual meetings
  # @return [String, nil] The URL or nil if not present
  def format_url
    event.url
  end

  # Format description including URL if present
  # @return [String, nil] The formatted description with URL
  def format_description_with_url
    parts = []
    parts << format_description if format_description
    parts << "Virtual Meeting URL: #{format_url}" if format_url
    parts.join("\n\n")
  end

  def add_optional_params(params)
    params[:description] = url_encode(format_description_with_url) if format_description || format_url
    params[:location] = url_encode(format_location) if format_location

    if event.show_attendees && event.attendees&.any?
      params[:attendees] = event.attendees.join(',')
    end

    params
  end

  # Get the list of attendees if showing attendees is enabled
  # @return [Array<String>] The list of attendees or empty array if disabled/none present
  def attendees_list
    return [] unless event.show_attendees && event.attendees&.any?
    event.attendees
  end
end
