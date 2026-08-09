# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

CalInvite is a Ruby gem for generating calendar invitations (URLs and .ics files) across multiple platforms: Google, Outlook, Outlook 365, Yahoo, Apple iCal, and generic .ics. Ruby >= 3.0.0, Rails 6.0–8.0 compatible, depends on `activesupport`.

## Commands

```bash
bundle install          # install dependencies
rake test                # run full test suite (default rake task)
rake test TEST=test/cal_invite/event_test.rb   # run a single test file
ruby -Itest -Ilib test/cal_invite/event_test.rb # run a single test file directly
rake rdoc                # generate RDoc documentation into doc/
rake rdoc:clean          # remove generated doc/
```

Tests are Minitest-based, files live under `test/cal_invite/`, named `*_test.rb`. Coverage is collected via SimpleCov (see `coverage/`).

## Architecture

- **`CalInvite` module** (`lib/cal_invite.rb`) — top-level entry point. Holds a singleton `CalInvite.configuration` (a `Configuration` instance) set via `CalInvite.configure { |c| ... }`. Mixes in `Caching` at the module level for class-level cache helpers.

- **`CalInvite::Event`** (`lib/cal_invite/event.rb`) — the central object. Holds all event attributes (title, start/end time, location, url, attendees, timezone, notes, multi-day sessions, all-day flag). `generate_calendar_url(provider)` is the main API: it validates the event, checks the cache (MD5 hash of all attributes + provider as key), and if not cached, resolves `CalInvite::Providers::<CapitalizedProvider>`, instantiates it with `self`, and calls `#generate`. Location and virtual-meeting URL are intentionally separate fields (not merged) so each provider can format them appropriately.

- **`CalInvite::Providers`** (`lib/cal_invite/providers.rb`) — namespace with `SUPPORTED_PROVIDERS = %i[google ical outlook yahoo ics office365]`. Provider classes are autoloaded from `lib/cal_invite/providers/*.rb`. To add a new provider: create a class extending `BaseProvider`, implement `#generate`, register it here with `autoload`, and add its symbol to `SUPPORTED_PROVIDERS`.

- **`BaseProvider`** (`lib/cal_invite/providers/base_provider.rb`) — abstract base class (note: it's a top-level `class BaseProvider`, not namespaced under `CalInvite::Providers`). Defines the `#generate` contract (must raise `NotImplementedError` if not overridden) plus shared helpers used by subclasses: URL-building (`url_encode`, `format_description`, `format_location`, `format_url`, `format_description_with_url`, `add_optional_params`) and iCalendar property formatting (`attendees_list`, `attendee_emails`, `attendee_line`, `organizer_line`, `status_line`, `geo_line`, `transp_line`, `class_line`, `rrule_line`, `valarm_lines`, `local_wall_time`, `vtimezone_lines`). Each concrete provider (`Google`, `Outlook`, `Office365`, `Yahoo`, `Ical`, `Ics`) builds a provider-specific URL or content string from the `Event` using these helpers.

- **`Ics` / `IcsContent` providers** (`ics.rb`, `ics_content.rb`) — generate actual `.ics` file content (RFC 5545) rather than a URL, for direct download flows (see README's `send_data` controller example). `IcsDownload` lives in `ics_content.rb` alongside `IcsContent` (not an alias). All ics-family providers accept a `method:` (`:publish`/`:request`/`:cancel`/`:reply`) passed through `Event#generate_calendar_url` — `:request` plus `Event#organizer` produces an RFC 5545 meeting request that mail clients render with RSVP actions; `:cancel` (reusing the same `Event#uid`, with `Event#sequence` bumped) produces a real cancellation; `:reply` omits `RSVP=TRUE` on `ATTENDEE` lines (a reply doesn't request a further response). `Event#uid` is stable (auto-generated and memoized per instance, or pass your own) — required so a later `:request`/`:cancel` is recognized as updating the original invite rather than creating a new one. `Event#attendees` entries can be plain email strings or `{ email:, name:, partstat: }` hashes (`partstat:` drives `PARTSTAT=` on the `ATTENDEE` line, default `NEEDS-ACTION`). Optional `Event` fields `geo`, `reminders`, `busy`, `visibility`, `rrule`, `calendar_name` map to `GEO:`, `VALARM`, `TRANSP:`, `CLASS:`, `RRULE:`, and `X-WR-CALNAME` respectively. See `CONFIGURATION.md`.
- **Timezones** — `:ics`/`:ical` build a real `VTIMEZONE` (via `CalInvite::IcalTimezone`, backed by `tzinfo`) for any recognized IANA `timezone` other than `'UTC'`, and correctly convert `start_time`/`end_time` (always UTC) to that zone's local wall-clock time for `DTSTART;TZID=...`. `'UTC'` uses plain `Z`-suffixed timestamps with no `VTIMEZONE`.

- **`Caching`** (`lib/cal_invite/caching.rb`) — an `ActiveSupport::Concern` mixed into `CalInvite` at the class level. Provides `fetch_from_cache`, `write_to_cache`, `read_from_cache`, `clear_cache!`, `clear_event_cache!`, `clear_provider_cache!`, all keyed under `CalInvite.configuration.cache_prefix`. Works with any `ActiveSupport::Cache::Store`-compatible store, or a custom object responding to `read`/`write`/`delete`. See also `CACHING.md`.

- **`Configuration`** (`lib/cal_invite/configuration.rb`) — holds `cache_store`, `cache_prefix` (default `'cal_invite'`), `cache_expires_in` (default 24 hours), `webhook_secret`, `timezone` (default `'UTC'`). `cache_store=` accepts `:memory_store`, `:null_store`, or any object implementing `read`/`write`/`delete`.

## Conventions

- Always pass times to `Event.new` in UTC; use the `timezone` attribute only to control display/formatting in the generated invite.
- `location` (physical) and `url` (virtual meeting link) are kept as distinct fields throughout the provider layer — don't conflate them when adding provider logic.
- All-day events skip `start_time`/`end_time` validation; multi-day events use the separate `multi_day_sessions` array instead of `start_time`/`end_time`.
- YARD-style doc comments (`@param`, `@return`, `@example`) are used throughout `lib/` and feed the RDoc-generated docs published to GitHub Pages (`.github/workflows/documentation.yml`) — keep them accurate when changing public method signatures.
- CalInvite is outbound-only: it renders `.ics` content/URLs and has no concept of inbound RSVP replies, provider guest-permission flags, or attendee-proposed reschedules (`COUNTER`). See CONFIGURATION.md's "Tracking RSVPs" section for what host apps need to build on top, and why.

## Example app (`Example/calendar_app`)

Rails 8.1 app demonstrating the gem. Its Gemfile depends on the **published** `cal-invite` gem (never commit it pointing at `path: "../.."`) — when testing example-app changes that rely on unreleased gem code (like the `Meeting` demo below, which needs the still-unreleased 0.2.0), temporarily uncomment the `path: "../.."` line locally, `bundle install`, test, then revert the Gemfile and re-run `bundle install` against rubygems before committing. `Meeting`/`MeetingAttendee` (with a migration) is a working reference implementation of the `uid`/`sequence` persistence pattern CONFIGURATION.md describes — see `app/models/meeting.rb`, `app/controllers/meetings_controller.rb` (create/reschedule/cancel), and `app/controllers/event_replies_controller.rb` (illustrative inbound `METHOD:REPLY` parsing, not wired to a real inbound-email provider). This demo won't actually run against the currently-published gem until 0.2.0 ships.
