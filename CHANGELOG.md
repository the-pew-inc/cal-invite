# Cal Invite

## [v0.2.0] - 2026-08-09

- Add `Event#organizer` and a `method:` option (`:publish`/`:request`/`:cancel`) to `generate_calendar_url`, so ics/ical output can carry `METHOD:REQUEST`/`METHOD:CANCEL` + `ORGANIZER`/`SEQUENCE`/`STATUS`, matching what mail clients (Gmail, Outlook, Apple Mail) need to render an attached `.ics` as an RSVP-capable meeting invite (or a real cancellation) rather than a plain file
- `ATTENDEE` lines now include `CUTYPE`/`ROLE`/`PARTSTAT`
- `IcsDownload.headers`/`.wrap_for_download` accept `method:` to add the matching `method=REQUEST` Content-Type parameter
- Fix a `superclass mismatch` crash when both the `:ics` provider and `IcsDownload`/`IcsContent` were loaded (dead duplicate `Ics`/`Ical` class definitions in `ics_content.rb`)
- **Fix: stable `UID`.** `Event#uid` is now a real attribute (auto-generated and memoized per `Event` instance, or pass your own) instead of the ics/ical/ics_content providers each minting a fresh random UID on every `generate` call — required for mail/calendar clients to recognize a `:request` update or `:cancel` as referring to a previously sent invite rather than a new, unrelated event. See new `Event#sequence` (defaults to `0`) and CONFIGURATION.md's "Updating and cancelling invites".
- **Fix: real `VTIMEZONE`.** `:ics`/`:ical` now emit a complete `VTIMEZONE` component (`STANDARD`/`DAYLIGHT` observances with correct offsets and `RRULE`s, derived from TZInfo's transition data) for any recognized IANA timezone, instead of an empty/absent block. `DTSTART;TZID=...`/`DTEND;TZID=...` are also now correctly converted from UTC to that zone's local wall-clock time — previously the UTC clock digits were emitted verbatim under a non-UTC `TZID`, mislabeling the time. `'UTC'` continues to use plain `Z`-suffixed timestamps with no `VTIMEZONE`, as before.
- Add `tzinfo` as an explicit gem dependency (previously relied on it only transitively via `activesupport`).
- `Event#attendees` entries can now be `{ email:, name:, partstat: }` hashes (plain email strings still work) — `ATTENDEE` lines gain `CN=` and a settable `PARTSTAT` (`:accepted`/`:declined`/`:tentative`/`:needs_action`/`:delegated`) instead of always `NEEDS-ACTION`.
- Add `method: :reply`, for building an attendee's `METHOD:REPLY` back to an organizer (omits `RSVP=TRUE`, honors each attendee's `partstat:`).
- Add `Event#geo` (`GEO:` property), `Event#reminders` (`VALARM` blocks), `Event#busy` (`TRANSP:`), `Event#visibility` (`CLASS:`), `Event#rrule` (raw `RRULE:` recurrence value), and `Event#calendar_name` (`X-WR-CALNAME` on the `VCALENDAR`) — all optional, all emitted by `:ics`/`:ical`/`IcsContent`.
- CONFIGURATION.md: add "Tracking RSVPs", "Guest permissions", and "Attendee-proposed reschedules (COUNTER)" — the gem is outbound-only (renders `.ics`/URLs), so RSVP replies, Google/Outlook-style guest permissions, and attendee-proposed time changes all require the host app to build something on top; these sections lay out what and how (inbound-reply webhook, provider-API alternative, why `COUNTER` isn't implemented).
- `Example/calendar_app`: add a working `Meeting`/`MeetingAttendee` persistence example (migration + models + `MeetingsController#create`/`#reschedule`/`#cancel` + `MeetingMailer`) demonstrating the `uid`/`sequence` lifecycle end-to-end, plus an illustrative `EventRepliesController` showing how to parse an inbound `METHOD:REPLY` email. The example app now points at the local gem (`path: "../.."`) instead of the last published release, so it always reflects the in-progress version.

## [Released]

## [v0.1.7] - 2025-11-09

- Upgrading to support Rails 8.1
- Support gems upgrades

## [v0.1.6] - 2024-12-20

- Adding Mailer example

## [v0.1.5] - 2024-12-19

- Should deploy the doc to a GitHub page
- Fixing a version number in the CHANGELOG file

## [v0.1.4] - 2024-12-19

- Add support to RDoc

## [v0.1.3] - 2024-12-19

- Apple iCal and ics file can now be either generated or wrap to be downloaded
- Add Caching management support
- Add CACHING.md for more details about how to use caching in a Rails app
- Updating the README file to reflect latest usage changes
- Minor bug fixes and improvments.

## [v0.1.2] - 2024-12-17

⚠️ This version should not be used

- Add support to Microsoft office 365 calendar invite URL
- Update the README
- Add an example
- Better testing

## [v0.1.1] - 2024-12-17

⚠️ This version should not be used

Fixing a bug in the gemspec file

## [Unreleased]

## [v0.1.0] - 2024-12-17

First public release of the Calendar Invite gem

Support the calendar invites for the following calendars:

- Microsoft Outlook
- Google Calendar
- Yahoo Calendar

Support Apple iCal

Support other calendars via .ics
