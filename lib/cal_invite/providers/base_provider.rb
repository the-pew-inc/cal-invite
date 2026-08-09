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
      params[:attendees] = attendee_emails.join(',')
    end

    params
  end

  # Get the list of attendees if showing attendees is enabled
  # @return [Array<String, Hash>] The list of attendees (email strings or
  #   { email:, name:, partstat: } hashes) or empty array if disabled/none present
  def attendees_list
    return [] unless event.show_attendees && event.attendees&.any?
    event.attendees
  end

  # Plain email addresses for all attendees, regardless of whether they were
  # given as strings or { email:, name:, partstat: } hashes.
  # @return [Array<String>]
  def attendee_emails
    attendees_list.map { |attendee| attendee_email(attendee) }
  end

  # @param attendee [String, Hash] An attendee as given in Event#attendees
  # @return [String] The attendee's email address
  def attendee_email(attendee)
    attendee.is_a?(Hash) ? (attendee[:email] || attendee["email"]) : attendee.to_s
  end

  PARTSTAT_VALUES = {
    accepted: "ACCEPTED",
    declined: "DECLINED",
    tentative: "TENTATIVE",
    needs_action: "NEEDS-ACTION",
    delegated: "DELEGATED"
  }.freeze

  # Formats a full ATTENDEE property line for iCalendar output.
  #
  # @param attendee [String, Hash] An email string, or a hash like
  #   { email:, name:, partstat: } for a display name and/or specific RSVP status
  # @return [String] The formatted ATTENDEE line
  def attendee_line(attendee)
    email = attendee_email(attendee)
    name = attendee.is_a?(Hash) ? (attendee[:name] || attendee["name"]) : nil
    partstat_key = attendee.is_a?(Hash) ? (attendee[:partstat] || attendee["partstat"]) : nil

    cn = name ? %(;CN="#{name}") : ""
    partstat = PARTSTAT_VALUES[partstat_key&.to_sym] || "NEEDS-ACTION"
    # A REPLY carries the responding attendee's own status back to the organizer;
    # RSVP is meaningless there since no further response is being requested.
    rsvp = method == :reply ? "" : ";RSVP=TRUE"

    "ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=#{partstat}#{rsvp}#{cn}:mailto:#{email}"
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

  # Format the GEO property from Event#geo.
  # @return [String, nil] The formatted GEO line, or nil if no geo is set
  def geo_line
    return nil unless event.geo

    lat, lng = event.geo.is_a?(Hash) ? [event.geo[:lat] || event.geo["lat"], event.geo[:lng] || event.geo["lng"]] : event.geo
    return nil unless lat && lng

    "GEO:#{lat};#{lng}"
  end

  # The TRANSP property, from Event#busy (default true).
  # @return [String] "TRANSP:OPAQUE" (busy) or "TRANSP:TRANSPARENT" (free)
  def transp_line
    event.busy == false ? "TRANSP:TRANSPARENT" : "TRANSP:OPAQUE"
  end

  # The CLASS property, from Event#visibility (default :public).
  # @return [String] e.g. "CLASS:PUBLIC"
  def class_line
    "CLASS:#{(event.visibility || :public).to_s.upcase}"
  end

  # The RRULE property, from Event#rrule, if set.
  # @return [String, nil] e.g. "RRULE:FREQ=WEEKLY;COUNT=5", or nil if no rrule is set
  def rrule_line
    return nil unless event.rrule

    value = event.rrule.to_s
    value.start_with?("RRULE:") ? value : "RRULE:#{value}"
  end

  # Builds VALARM sub-components from Event#reminders (minutes-before-start values).
  # @return [Array<String>] iCalendar lines, one VALARM block per reminder, or [] if none
  def valarm_lines
    return [] unless event.reminders&.any?

    event.reminders.flat_map do |minutes|
      ["BEGIN:VALARM", "TRIGGER:-PT#{minutes.to_i}M", "ACTION:DISPLAY", "DESCRIPTION:Reminder", "END:VALARM"]
    end
  end
end
