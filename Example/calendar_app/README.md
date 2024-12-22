# Calendar App Example

This example application demonstrates how to use the [cal-invite](https://github.com/the-pew-inc/cal-invite) gem to generate calendar invites across multiple platforms. The app shows different types of calendar events and how to integrate them with various calendar providers.

## Installation

1. Clone this repository
2. Install dependencies:
```bash
bundle install
```

## Gem Integration

You can integrate the cal-invite gem in two ways:

1. Direct from source (development):
```ruby
# Gemfile
gem "cal-invite", path: "../../"
```

2. From RubyGems (production):
```ruby
# Gemfile
gem "cal-invite"
```

## Features Demonstration

The example app showcases three different types of calendar events:

1. **Simple Event**
   - Basic meeting with location
   - Demonstrates core functionality
   - Uses timezone handling

2. **All-Day Event**
   - Full-day company event
   - Shows all-day event handling
   - Includes description and location

3. **Complete Event**
   - Demonstrates all available features
   - Includes attendees
   - Contains meeting URL and notes
   - Full timezone support

## Supported Calendar Providers

The application supports multiple calendar providers through the `CalInvite::Providers::SUPPORTED_PROVIDERS`:

- Google Calendar
- Outlook
- Office 365
- Yahoo Calendar
- iCal download
- ICS file download

## Implementation Details

The main controller (`CalendarsController`) demonstrates how to:

- Create different types of events
- Generate calendar links for various providers
- Handle ICS file downloads
- Work with timezones
- Manage attendees and event metadata

### Example Usage

Here's a basic example of creating a simple event:

```ruby
def create_simple_event
  start_time = 5.days.from_now.change(hour: 10)
  end_time = 5.days.from_now.change(hour: 12)
  pacific_time = TZInfo::Timezone.get('America/Los_Angeles')
  
  CalInvite::Event.new(
    title: "Meeting at Apple's Historical HQ",
    start_time: pacific_time.local_to_utc(start_time),
    end_time: pacific_time.local_to_utc(end_time),
    location: "1 Infinite Loop, Cupertino, CA 95014",
    timezone: "America/Los_Angeles"
  )
end
```

### ICS File Downloads

The application provides ICS file download functionality:

```ruby
def download_ics
  event = create_event(params[:event_type])
  provider = params[:provider]&.to_sym || :ics
  
  content = CalInvite::Providers.const_get(provider.to_s.capitalize).new(event).generate
  filename = generate_filename(event)
  
  send_data(
    content,
    filename: filename,
    type: 'text/calendar; charset=UTF-8',
    disposition: 'attachment'
  )
end
```

## Interface

The example application provides a simple web interface where you can:

- View different types of events
- Generate calendar links for various providers
- Download ICS files
- See how timezone handling works
- Test different event configurations

## Contributing

Feel free to submit issues and enhancement requests through the main [cal-invite repository](https://github.com/the-pew-inc/cal-invite).

## License

This example application is available as open source under the terms of the MIT License.