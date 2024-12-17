# CalInvite

A Ruby gem for generating calendar invitations across multiple calendar platforms with caching and webhook support.

[![Gem Version](https://badge.fury.io/rb/cal-invite.svg)](https://badge.fury.io/rb/cal-invite)
[![Ruby](https://github.com/the-pew-inc/cal-invite/workflows/Ruby/badge.svg)](https://github.com/yourusername/cal-invite/actions)

## Compatibility

- Ruby >= 2.7.0
- Rails 6.0, 6.1, 7.0, 7.1, 8.0
- ActiveSupport/ActiveModel compatible frameworks

## Supported Calendar Platforms

Direct Integration:
- Google Calendar
- Microsoft Outlook
- Yahoo Calendar
- Apple iCal
- Standard .ics file generation

Any calendar application that supports the iCalendar (.ics) standard should work, including but not limited to:
- ProtonCalendar
- FastMail Calendar
- Thunderbird Calendar
- Zoho Calendar
- Microsoft Teams Calendar
- Zoom Calendar Integration
- Office 365 Calendar

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

## Configuration

Create an initializer in your Rails application:

```ruby
# config/initializers/cal-invite.rb
CalendarInvites.configure do |config|
  # Cache store configuration (defaults to :memory_store)
  # For production, recommend using Rails.cache
  config.cache_store = Rails.cache
  
  # Prefix for cache keys (optional)
  config.cache_prefix = 'my_app_cal-invite'
  
  # Secret for webhook signature verification (required for webhooks)
  config.webhook_secret = Rails.application.credentials.calendar_webhook_secret
  
  # Default timezone (defaults to 'UTC')
  config.timezone = 'UTC'
end
```

## Usage

### Basic Event Creation

```ruby
event = CalInvite::Event.new(
  title: "Team Meeting",
  start_time: Time.now,
  duration: 3600, # 1 hour in seconds
  description: "Weekly team sync",
  location: "Conference Room A",
  attendees: ["person@example.com"]
)

yahoo_url = event.calendar_url(:yahoo)
ical_url = event.calendar_url(:ical)
outlook_url = event.calendar_url(:outlook)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cal-invite. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/cal-invite/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Cal::Invite project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/cal-invite/blob/master/CODE_OF_CONDUCT.md).
