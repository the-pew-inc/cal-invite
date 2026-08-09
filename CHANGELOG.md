# Cal Invite

## [v0.2.0] - 2026-08-09

- Add `Event#organizer` and a `method:` option (`:publish`/`:request`) to `generate_calendar_url`, so ics/ical output can carry `METHOD:REQUEST` + `ORGANIZER`/`SEQUENCE`/`STATUS`, matching what mail clients (Gmail, Outlook, Apple Mail) need to render an attached `.ics` as an RSVP-capable meeting invite rather than a plain file
- `ATTENDEE` lines now include `CUTYPE`/`ROLE`/`PARTSTAT`
- `IcsDownload.headers`/`.wrap_for_download` accept `method:` to add the matching `method=REQUEST` Content-Type parameter
- Fix a `superclass mismatch` crash when both the `:ics` provider and `IcsDownload`/`IcsContent` were loaded (dead duplicate `Ics`/`Ical` class definitions in `ics_content.rb`)

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
