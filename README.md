# CalendarInvites

A Ruby gem for generating calendar invitations across multiple calendar platforms with caching and webhook support.

[![Gem Version](https://badge.fury.io/rb/calendar_invites.svg)](https://badge.fury.io/rb/calendar_invites)
[![Ruby](https://github.com/yourusername/calendar_invites/workflows/Ruby/badge.svg)](https://github.com/yourusername/calendar_invites/actions)

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
gem 'calendar_invites'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install calendar_invites
```

## Configuration

Create an initializer in your Rails application:

```ruby
# config/initializers/calendar_invites.rb
CalendarInvites.configure do |config|
  # Cache store configuration (defaults to :memory_store)
  # For production, recommend using Rails.cache
  config.cache_store = Rails.cache
  
  # Prefix for cache keys (optional)
  config.cache_prefix = 'my_app_calendar_invites'
  
  # Secret for webhook signature verification (required for webhooks)
  config.webhook_secret = Rails.application.credentials.calendar_webhook_secret
  
  # Default timezone (defaults to 'UTC')
  config.timezone = 'UTC'
end
```

## Usage

### Basic Event Creation

```ruby
event = CalendarInvites::Event.new(
  title: "Team Meeting",
  event_url: "https://meet.google.com/abc-defg-hij",
  address: "123 Main St, City, Country",
  notes: "Quarterly planning meeting",
  logo: "https://company.com/logo.png", # or Rails.application.assets.find_asset('logo.png')
  start_date: DateTime.new(2024, 1, 1, 9, 0),
  end_date: DateTime.new(2024, 1, 1, 10, 0),
  # alternatively, use duration instead of end_date
  # duration: 60.minutes,
  timezone: "America/New_York"
)
```

### Generating Calendar Files

```ruby
# Generate for specific platform
google_calendar = event.calendar_file(:google)
outlook_calendar = event.calendar_file(:outlook)
yahoo_calendar = event.calendar_file(:yahoo)
ical_calendar = event.calendar_file(:ical)
standard_ics = event.calendar_file(:ics)

# Files are automatically cached
```

### Cache Management

```ruby
# Invalidate cache for all providers
event.invalidate_cache!

# Cache is automatically invalidated when event is updated
event.update_attendees!
```

### Webhook Integration

```ruby
# Register webhook
CalendarInvites::Webhooks.register(
  :google,
  event.uid,
  "https://yourapp.com/webhooks/calendar"
)

# In your webhook controller
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def calendar
    return head :unauthorized unless CalendarInvites::Webhooks.verify_signature(request)
    
    # Handle webhook
    case request.headers['X-Calendar-Action']
    when 'accept'
      # Handle acceptance
    when 'decline'
      # Handle decline
    when 'tentative'
      # Handle maybe
    end
    
    head :ok
  end
end
```

### Rails Routes Integration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :events do
    member do
      get 'calendar/:provider', to: 'events#calendar', as: :calendar
      post 'update_attendees', to: 'events#update_attendees'
    end
  end
  
  post 'webhooks/calendar', to: 'webhooks#calendar'
end

# app/controllers/events_controller.rb
class EventsController < ApplicationController
  def calendar
    event = Event.find(params[:id])
    calendar_event = CalendarInvites::Event.new(event.to_calendar_params)
    
    send_data calendar_event.calendar_file(params[:provider]),
              filename: "#{event.title}.ics",
              type: 'text/calendar'
  end
  
  def update_attendees
    event = Event.find(params[:id])
    calendar_event = CalendarInvites::Event.new(event.to_calendar_params)
    calendar_event.update_attendees!
    
    head :ok
  end
end
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
