# frozen_string_literal: true

require 'tzinfo'
require 'date'

# lib/cal_invite/ical_timezone.rb
module CalInvite
  # Builds RFC 5545 VTIMEZONE components and converts UTC times to local wall-clock
  # time for a given IANA/Olson timezone identifier, using TZInfo (already pulled in
  # transitively via activesupport).
  #
  # Both entry points fail soft: if `tzid` isn't a TZInfo-recognized identifier (e.g.
  # a raw UTC offset string like "+01:00", or 'UTC' itself), they return nil so
  # callers can fall back to their previous behavior instead of raising.
  #
  # @api private
  module IcalTimezone
    module_function

    # Converts a UTC time to local wall-clock time for the given timezone.
    #
    # @param tzid [String] An IANA timezone identifier, e.g. "America/New_York"
    # @param utc_time [Time] The time to convert (interpreted as UTC)
    # @return [Time, nil] The local wall-clock time, or nil if tzid is unrecognized
    def local_time(tzid, utc_time)
      return nil if tzid.nil? || tzid.to_s.strip.empty? || tzid.to_s.upcase == 'UTC'

      TZInfo::Timezone.get(tzid.to_s).to_local(utc_time.utc)
    rescue TZInfo::InvalidTimezoneIdentifier
      nil
    end

    # Builds a complete VTIMEZONE component (STANDARD/DAYLIGHT observances with
    # RRULEs derived from the timezone's actual transition rules) for the given
    # timezone identifier.
    #
    # @param tzid [String] An IANA timezone identifier, e.g. "America/New_York"
    # @return [Array<String>, nil] iCalendar lines for the VTIMEZONE component, or
    #   nil if tzid is unrecognized, is UTC, or the component can't be built
    def vtimezone_lines(tzid)
      return nil if tzid.nil? || tzid.to_s.strip.empty? || tzid.to_s.upcase == 'UTC'

      tz = TZInfo::Timezone.get(tzid.to_s)
      current = tz.period_for(Time.now.utc)

      if current.dst?
        dst_period = current
        std_period = period_before(tz, dst_period)
      else
        std_period = current
        dst_period = period_after(tz, std_period)
        dst_period = nil unless dst_period&.dst?
      end

      lines = ["BEGIN:VTIMEZONE", "TZID:#{tzid}"]

      if std_period && dst_period
        lines.concat(observance_lines('STANDARD', dst_period, std_period))
        lines.concat(observance_lines('DAYLIGHT', std_period, dst_period))
      else
        lines.concat(fixed_observance_lines(std_period || dst_period || current))
      end

      lines << "END:VTIMEZONE"
      lines
    rescue StandardError
      # Never let an exotic/edge-case timezone break calendar generation —
      # worst case the VEVENT ends up without a VTIMEZONE definition.
      nil
    end

    # @api private
    def period_before(tz, period)
      return nil unless period.starts_at

      tz.period_for(period.starts_at.to_time - 1)
    end

    # @api private
    def period_after(tz, period)
      return nil unless period&.ends_at

      tz.period_for(period.ends_at.to_time)
    end

    # @api private
    def observance_lines(kind, from_period, to_period)
      transition_time = from_period.local_ends_at.to_time

      [
        "BEGIN:#{kind}",
        "DTSTART:#{transition_time.strftime('%Y%m%dT%H%M%S')}",
        "TZOFFSETFROM:#{format_offset(from_period.offset.observed_utc_offset)}",
        "TZOFFSETTO:#{format_offset(to_period.offset.observed_utc_offset)}",
        "TZNAME:#{to_period.offset.abbreviation}",
        rrule_line(transition_time),
        "END:#{kind}"
      ]
    end

    # @api private
    def fixed_observance_lines(period)
      [
        "BEGIN:STANDARD",
        "DTSTART:16010101T000000",
        "TZOFFSETFROM:#{format_offset(period.offset.observed_utc_offset)}",
        "TZOFFSETTO:#{format_offset(period.offset.observed_utc_offset)}",
        "TZNAME:#{period.offset.abbreviation}",
        "END:STANDARD"
      ]
    end

    # Derives a YEARLY RRULE (e.g. "2nd Sunday in March") from a transition date.
    #
    # @api private
    def rrule_line(time)
      wday_names = %w[SU MO TU WE TH FR SA]
      days_in_month = Date.new(time.year, time.month, -1).day
      nth = (time.day - 1) / 7 + 1
      nth = -1 if time.day + 7 > days_in_month

      "RRULE:FREQ=YEARLY;BYMONTH=#{time.month};BYDAY=#{nth}#{wday_names[time.wday]}"
    end

    # @api private
    def format_offset(seconds)
      sign = seconds.negative? ? '-' : '+'
      abs = seconds.abs
      format('%<sign>s%<hours>02d%<minutes>02d', sign: sign, hours: abs / 3600, minutes: (abs % 3600) / 60)
    end
  end
end
