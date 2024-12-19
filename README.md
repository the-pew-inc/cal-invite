# 📅 CalInvite

A Ruby gem for generating calendar invitations across multiple calendar platforms with caching and webhook support.

[![Gem Version](https://badge.fury.io/rb/cal-invite.svg)](https://badge.fury.io/rb/cal-invite)
![Build Status](https://github.com/the-pew-inc/cal-invite/actions/workflows/main.yml/badge.svg)

[![License](https://img.shields.io/github/license/the-pew-inc/cal-invite.svg)]

## Compatibility

- Ruby >= 3.0.0
- Rails 6.0, 6.1, 7.0, 7.1, 8.0

## Supported Calendar Platforms

Direct Integration:
- Apple iCal
- Microsoft Outlook
- Microsoft Outlook 365
- Google Calendar
- Yahoo Calendar
- Standard .ics file generation

Any calendar application that supports the iCalendar (.ics) standard should work, including but not limited to:
- Proton Calendar
- FastMail Calendar
- Thunderbird Calendar
- Zoho Calendar
- Microsoft Teams Calendar
- Zoom Calendar Integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cal-invite'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install cal-invite
```

## Usage

### Basic Event Creation

```ruby
# Single day event
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.current,
  end_time: Time.current + 2.hours,
  description: "Weekly team sync",
  location: "Conference Room A",
  url: "https://zoom.us/j/123456789",
  attendees: ["person@example.com"],
  show_attendees: true,
  timezone: "America/New_York",
  notes: "Please bring your laptop"
)

# Multi-day event
event = CalInvite::Event.new(
  title: "Training Workshop",
  multi_day_sessions: [
    {
      start_time: Time.parse("2024-03-01 08:00:00 UTC"),
      end_time: Time.parse("2024-03-01 17:00:00 UTC")
    },
    {
      start_time: Time.parse("2024-03-02 09:00:00 UTC"),
      end_time: Time.parse("2024-03-02 13:00:00 UTC")
    }
  ],
  description: "Advanced Ruby Training",
  location: "Training Center",
  url: "https://zoom.us/j/123456789",
  timezone: "America/New_York",
  notes: "Bring your own laptop"
)

ical_url       = event.calendar_url(:ical)
google_url     = event.calendar_url(:google)
outlook_url    = event.calendar_url(:outlook)
outlook365_url = event.calendar_url(:office365)
yahoo_url      = event.calendar_url(:yahoo)
```

### ICS
Just get the ICS content:
```ruby
event = CalInvite::Event.new(
  title: "Meeting",
  start_time: Time.now.utc,
  end_time: Time.now.utc + 1.hour
)

# Get raw content
content = CalInvite::Providers::IcsContent.new(event).generate
```
Get content with download headers:

```ruby
# Get content wrapped for download
content = CalInvite::Providers::IcsContent.new(event).generate
download = CalInvite::Providers::IcsDownload.wrap_for_download(content, event.title)

# In a Rails controller:
send_data(download[:content], download[:headers])
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

Add test(s) as necessary.

Run all the tests before submiting: `bundle exec rake test`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/the-pew-inc/cal-invite. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/the-pew-inc/cal-invite/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cal::Invite project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/the-pew-inc/cal-invite/blob/master/CODE_OF_CONDUCT.md).
