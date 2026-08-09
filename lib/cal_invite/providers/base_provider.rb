# frozen_string_literal: true

# app/lib/base_provider.rb
# Base class for calendar providers that implements common functionality
# and defines the interface that all providers must implement.
#
# @abstract Subclass and override {#generate} to implement a calendar provider
class BaseProvider
  attr_reader :event, :method

  # Initialize a new calendar provider
  #
  # @param event [CalInvite::Event] The event to generate a calendar URL for
  # @param method [Symbol] The iCalendar METHOD (:publish or :request). Only
  #   meaningful to the ics-family providers; URL-based providers ignore it.
  def initialize(event, method: :publish)
    @event = event
    @method = method
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

  # Format the ORGANIZER property for iCalendar output
  # @return [String, nil] The formatted ORGANIZER line, or nil if no organizer is set
  def organizer_line
    return nil unless event.organizer && event.organizer[:email]

    name = event.organizer[:name]
    cn = name ? %(;CN="#{name}") : ""
    "ORGANIZER#{cn}:mailto:#{event.organizer[:email]}"
  end

  # The STATUS property, driven by the iCalendar METHOD in use.
  # @return [String] "STATUS:CANCELLED" for :cancel, "STATUS:CONFIRMED" otherwise
  def status_line
    method == :cancel ? "STATUS:CANCELLED" : "STATUS:CONFIRMED"
  end

  # Converts a time to local wall-clock time for the event's timezone, for use in
  # a `DTSTART;TZID=...`/`DTEND;TZID=...` property. Falls back to the time as given
  # (unconverted) when the timezone isn't a TZInfo-recognized identifier (e.g. 'UTC'
  # or a raw offset string), matching each provider's prior behavior for those cases.
  #
  # @param time [Time] The time to convert (interpreted as UTC)
  # @return [Time] The local wall-clock time
  def local_wall_time(time)
    CalInvite::IcalTimezone.local_time(event.timezone, time) || time
  end

  # Builds the VTIMEZONE component lines for the event's timezone, if applicable.
  # @return [Array<String>, nil] iCalendar lines, or nil for UTC/unrecognized timezones
  def vtimezone_lines
    CalInvite::IcalTimezone.vtimezone_lines(event.timezone)
  end
end
