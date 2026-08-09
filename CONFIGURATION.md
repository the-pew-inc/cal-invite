# Configuration Reference

Complete reference for every configurable option in CalInvite: `Event` attributes, providers, the `generate_calendar_url` call, ICS/email-invite delivery, and global `CalInvite.configure` settings.

For caching-specific detail, see [CACHING.md](CACHING.md).

## Table of Contents

- [Event attributes](#event-attributes)
- [Providers](#providers)
- [`generate_calendar_url`](#generate_calendar_url)
- [ICS content and downloads](#ics-content-and-downloads)
- [Email meeting invites (RSVP-capable)](#email-meeting-invites-rsvp-capable)
- [Updating and cancelling invites](#updating-and-cancelling-invites)
- [Timezones and VTIMEZONE](#timezones-and-vtimezone)
- [Global configuration (`CalInvite.configure`)](#global-configuration-calinviteconfigure)

## Event attributes

All attributes are set via `CalInvite::Event.new(attributes)` or `event.update_attributes(attributes)`.

| Attribute             | Type            | Required                              | Default | Notes |
|------------------------|-----------------|----------------------------------------|---------|-------|
| `title`                | `String`        | yes                                    | —       | Non-blank. |
| `start_time`           | `Time`          | yes, unless `all_day` or using `multi_day_sessions` | — | Always pass UTC. |
| `end_time`             | `Time`          | yes, unless `all_day` or using `multi_day_sessions` | — | Always pass UTC. |
| `description`          | `String`        | no                                     | `nil`   | Plain text; combined with `notes` in provider output. |
| `location`             | `String`        | no                                     | `nil`   | Physical location only. Kept separate from `url` so each provider formats it correctly. |
| `url`                  | `String`        | no                                     | `nil`   | Virtual meeting link (Zoom, Meet, Teams, etc). Kept separate from `location`. |
| `attendees`            | `Array<String>` | no                                     | `nil`   | Email addresses. Only emitted if `show_attendees` is `true`. |
| `show_attendees`       | `Boolean`       | no                                     | `false` | Gate for including `attendees` in generated output. |
| `organizer`             | `Hash`          | no, but required for `method: :request` | `nil`   | `{ name: "Jane Doe", email: "jane@example.com" }`. `name` is optional. See [Email meeting invites](#email-meeting-invites-rsvp-capable). |
| `timezone`             | `String`        | no                                     | `'UTC'` | Controls display/formatting only — does not affect how `start_time`/`end_time` are interpreted. Any IANA identifier (e.g. `'America/New_York'`) produces a correctly converted `DTSTART;TZID=...` plus a full `VTIMEZONE` block; see [Timezones and VTIMEZONE](#timezones-and-vtimezone). |
| `notes`                | `String`        | no                                     | `nil`   | Appended to the description. |
| `all_day`              | `Boolean`       | no                                     | `false` | When `true`, `start_time`/`end_time` validation is skipped. |
| `multi_day_sessions`   | `Array<Hash>`   | no                                     | `[]`    | `[{ start_time:, end_time: }, ...]`. Used instead of `start_time`/`end_time` for multi-session events. |
| `uid`                  | `String`        | no                                     | randomly generated, memoized per `Event` instance | Stable RFC 5545 identifier. **Must** be reused across calls when you send an update (`:request`) or cancellation (`:cancel`) for a previously sent invite — see [Updating and cancelling invites](#updating-and-cancelling-invites). |
| `sequence`             | `Integer`       | no                                     | `0`     | RFC 5545 SEQUENCE. Increment it yourself each time you resend a `:request`/`:cancel` for the same `uid`. |

```ruby
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.current.utc,
  end_time: Time.current.utc + 1.hour,
  description: "Weekly sync",
  location: "Conference Room A",
  url: "https://zoom.us/j/123456789",
  timezone: "America/New_York",
  attendees: ["person@example.com"],
  show_attendees: true,
  organizer: { name: "Jane Doe", email: "jane@example.com" },
  notes: "Bring your laptop"
)
```

## Providers

Pass one of these symbols to `generate_calendar_url`:

| Symbol      | Output                          | Notes |
|-------------|----------------------------------|-------|
| `:google`   | Google Calendar URL             | |
| `:outlook`  | Outlook (outlook.live.com) URL   | |
| `:office365`| Outlook 365 URL                 | |
| `:yahoo`    | Yahoo Calendar URL              | |
| `:ical`     | `.ics` content (`METHOD:PUBLISH` or `:REQUEST`) | Apple iCal / any iCalendar-compatible app |
| `:ics`      | `.ics` content (`METHOD:PUBLISH` or `:REQUEST`) | Generic RFC 5545 file |

`CalInvite::Providers::SUPPORTED_PROVIDERS` holds the full list programmatically.

`CalInvite::Providers::IcsContent` is also available directly (not via `generate_calendar_url`) if you want raw `.ics` content without going through `Event#generate_calendar_url`'s caching path — see [ICS content and downloads](#ics-content-and-downloads).

## `generate_calendar_url`

```ruby
event.generate_calendar_url(provider, method: :publish)
```

| Param     | Type     | Default    | Notes |
|-----------|----------|------------|-------|
| `provider`| `Symbol` | required   | One of the provider symbols above. |
| `method`  | `Symbol` | `:publish` | `:publish`, `:request`, or `:cancel`. Only honored by `:ics`/`:ical` — ignored by URL-based providers. `:request` requires `organizer` to be set on the event; see below. `:cancel` requires reusing the original `uid` — see [Updating and cancelling invites](#updating-and-cancelling-invites). |

Results are cached (when caching is configured) keyed on all event attributes, `provider`, and `method` together — changing any of them produces a distinct cache entry.

## ICS content and downloads

Two ways to get raw `.ics` content:

```ruby
# Via Event (goes through validation + caching)
content = event.generate_calendar_url(:ics, method: :publish)

# Directly via the provider (bypasses Event caching)
content = CalInvite::Providers::Ics.new(event, method: :publish).generate
```

To serve it as a downloadable file, use `IcsDownload`:

```ruby
result = CalInvite::Providers::IcsDownload.wrap_for_download(content, event.title, method: :publish)
# => { content: "BEGIN:VCALENDAR...", headers: { "Content-Type" => "text/calendar; charset=UTF-8", "Content-Disposition" => "attachment; filename=..." } }

send_data(result[:content], filename: "invite.ics", type: result[:headers]["Content-Type"], disposition: "attachment")
```

Or build headers directly:

```ruby
CalInvite::Providers::IcsDownload.headers("invite.ics", method: :publish)
# => { "Content-Type" => "text/calendar; charset=UTF-8", "Content-Disposition" => "attachment; filename=invite.ics" }
```

`method:` on `IcsDownload.headers`/`.wrap_for_download` defaults to `nil` (no `method=` parameter on the Content-Type header) for backward compatibility. Pass the same `method:` you used to generate the content — see below for why this must match.

## Email meeting invites (RSVP-capable)

A plain `.ics` attachment opens as a file in most mail clients. To get the
behavior services like Luma or Google Calendar produce — Gmail, Outlook, and
Apple Mail rendering the message as an invite with Accept/Decline actions —
two things must both be true, and they must agree with each other:

1. The `.ics` content itself must use `METHOD:REQUEST` and include an `ORGANIZER`.
2. The `Content-Type` header on the attachment/part must carry a matching `method=REQUEST` parameter.

```ruby
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.current.utc,
  end_time: Time.current.utc + 1.hour,
  timezone: "America/New_York",
  organizer: { name: "Jane Doe", email: "jane@example.com" },
  attendees: ["attendee@example.com"],
  show_attendees: true
)

content = event.generate_calendar_url(:ics, method: :request)

headers = CalInvite::Providers::IcsDownload.headers("team-meeting.ics", method: :request)
# => { "Content-Type" => "text/calendar; charset=UTF-8; method=REQUEST",
#      "Content-Disposition" => "attachment; filename=team-meeting.ics" }
```

With `method: :request`, the generated `.ics` also gets `SEQUENCE:0`, `STATUS:CONFIRMED`, and richer `ATTENDEE` lines (`CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE`) — all part of what RFC 5545 expects for a `REQUEST`.

If you're sending through ActionMailer, attach `content` with a matching `content_type` rather than `send_data`'s plain `text/calendar` type:

```ruby
attachments["team-meeting.ics"] = {
  mime_type: "text/calendar; method=REQUEST",
  content: content
}
```

Omit `method:` (or pass `method: :publish`) for a plain downloadable calendar file with no RSVP semantics.

## Updating and cancelling invites

Mail/calendar clients (Gmail, Outlook, Apple Mail) match a `REQUEST` update or a
`CANCEL` to an existing invite by **UID**, not by content — a new random UID is
indistinguishable from an unrelated new event. To send an update or cancellation
for an invite you sent earlier, reconstruct the `Event` with the **same `uid`**
and a **higher `sequence`** than what you sent originally:

```ruby
# Original invite
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.current.utc,
  end_time: Time.current.utc + 1.hour,
  organizer: { name: "Jane Doe", email: "jane@example.com" }
)
event.uid        # => e.g. "1786300000-abcdef0123456789@cal-invite" — persist this
original_content = event.generate_calendar_url(:ics, method: :request)

# ...later, rescheduling the same meeting...
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.current.utc + 1.day,
  end_time: Time.current.utc + 1.day + 1.hour,
  organizer: { name: "Jane Doe", email: "jane@example.com" },
  uid: "1786300000-abcdef0123456789@cal-invite",  # same as the original
  sequence: 1                                       # incremented
)
updated_content = event.generate_calendar_url(:ics, method: :request)

# ...or cancelling it entirely...
event.sequence = 2
cancellation = event.generate_calendar_url(:ics, method: :cancel)
```

If you don't pass `uid:` explicitly, `Event.new` generates one and memoizes it
on that instance — repeated `generate_calendar_url` calls on the *same* `Event`
object always reuse it, but a freshly constructed `Event` for the same
underlying meeting will not, unless you pass the original `uid` back in. In
practice this means: persist `event.uid` (e.g. alongside the meeting record in
your database) the first time you send a `:request`, and pass it back in on
every subsequent `:request`/`:cancel` for that meeting.

## Timezones and VTIMEZONE

For any `timezone` other than `'UTC'` that's a recognized IANA/Olson identifier
(e.g. `'America/New_York'`, `'Europe/London'`), the `:ics`/`:ical` providers:

1. Convert `start_time`/`end_time` (always supplied in UTC) to that zone's local
   wall-clock time for the `DTSTART;TZID=...`/`DTEND;TZID=...` properties.
2. Emit a full `VTIMEZONE` component with real `STANDARD`/`DAYLIGHT` observances
   (offsets, names, and `RRULE`s) derived from the timezone's actual transition
   rules via [TZInfo](https://github.com/tzinfo/tzinfo) — not just a bare `TZID`
   line — as RFC 5545 requires.

`'UTC'` needs neither: `DTSTART`/`DTEND` are emitted directly as `Z`-suffixed UTC
timestamps with no `VTIMEZONE` block, which every calendar client understands
unambiguously.

If `timezone` isn't a recognized IANA identifier (e.g. a raw offset string like
`'+01:00'`), both providers fall back to treating `start_time`/`end_time` as
already being in that zone's wall-clock time — the pre-existing behavior — since
there's no timezone database entry to convert against or build a `VTIMEZONE`
from.

## Global configuration (`CalInvite.configure`)

```ruby
# config/initializers/cal_invite.rb
CalInvite.configure do |config|
  config.cache_store = Rails.cache        # or :memory_store, :null_store, or a custom read/write/delete object
  config.cache_prefix = 'my_app_cal_invite'
  config.cache_expires_in = 3600           # seconds
  config.webhook_secret = ENV['CAL_INVITE_WEBHOOK_SECRET']
  config.timezone = 'UTC'
end
```

| Option              | Type                                   | Default        | Notes |
|---------------------|-----------------------------------------|----------------|-------|
| `cache_store`       | `:memory_store`, `:null_store`, or any object implementing `read`/`write`/`delete` | `nil` (caching disabled) | See [CACHING.md](CACHING.md) for full detail. |
| `cache_prefix`      | `String`                                | `'cal_invite'` | Namespaces cache keys. |
| `cache_expires_in`  | `Integer` (seconds)                     | `86400` (24h)  | |
| `webhook_secret`    | `String`                                | `nil`          | Reserved for webhook signature verification in consuming apps. |
| `timezone`          | `String`                                | `'UTC'`        | Configuration-level default; per-event `timezone` attribute takes precedence for that event's display formatting. |

Caching is disabled unless `cache_store` is set — without it, `generate_calendar_url` regenerates output on every call.
