# frozen_string_literal: true
# app/controllers/calendars_controller.rb
class CalendarsController < ApplicationController
  def index
    @simple_event = create_simple_event
    @all_day_event = create_all_day_event
    @complete_event = create_complete_event
    # Order providers to show online calendars first, then downloads
    @providers = (CalInvite::Providers::SUPPORTED_PROVIDERS - [:ics, :ical]).sort + [:ical, :ics]
  end

  def download_ics
    event = case params[:event_type]
            when 'simple'
              create_simple_event
            when 'all_day'
              create_all_day_event
            when 'complete'
              create_complete_event
            else
              raise ActionController::RoutingError.new('Not Found')
            end

    provider = params[:provider]&.to_sym || :ics
    raise ArgumentError, "Invalid provider" unless [:ics, :ical].include?(provider)

    # Use the provider directly from the gem
    provider_class = CalInvite::Providers.const_get(provider.to_s.capitalize)
    content = provider_class.new(event).generate

    # Generate filename based on event title and date
    filename = "#{event.title.downcase.gsub(/[^0-9A-Za-z.\-]/, '_')}_#{Time.now.strftime('%Y%m%d')}.ics"

    send_data(
      content,
      filename: filename,
      type: 'text/calendar; charset=UTF-8',
      disposition: 'attachment'
    )
  end

  def send_test_email
    event = create_apple_park_event
    CalendarInviteMailer.event_invitation(event).deliver_now
    redirect_to calendars_path, notice: 'Test email sent successfully!'
  end

  private

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

  def create_all_day_event
    CalInvite::Event.new(
      title: "Company All-Day Event",
      start_time: 10.days.from_now.beginning_of_day.utc,
      end_time: 10.days.from_now.end_of_day.utc,
      all_day: true,
      description: "Join us for our annual company event!",
      location: "123 Main Street, San Francisco, CA 94105",
      timezone: "America/Los_Angeles"
    )
  end

  def create_complete_event
    start_time = 15.days.from_now.change(hour: 14, min: 30)
    end_time = 15.days.from_now.change(hour: 16)
    pacific_time = TZInfo::Timezone.get('America/Los_Angeles')

    CalInvite::Event.new(
      title: "Full Feature Meeting Demo",
      start_time: pacific_time.local_to_utc(start_time),
      end_time: pacific_time.local_to_utc(end_time),
      description: "This is a demonstration of all available calendar invite features",
      location: "123 Lombard Street, San Francisco, CA 94105",
      url: "https://meet.google.com/demo",
      timezone: "America/Los_Angeles",
      attendees: ["demo@example.com", "test@example.com"],
      show_attendees: true,
      notes: "Please bring your laptop"
    )
  end

  def create_apple_park_event
    start_time = 5.days.from_now.change(hour: 9) # 9am PT
    end_time = 5.days.from_now.change(hour: 12)  # 12pm PT
    pacific_time = TZInfo::Timezone.get('America/Los_Angeles')

    CalInvite::Event.new(
      title: "Strategic Planning Meeting at Apple Park",
      start_time: pacific_time.local_to_utc(start_time),
      end_time: pacific_time.local_to_utc(end_time),
      description: <<~DESC,
        Join us for our quarterly strategic planning session at Apple Park.

        Agenda:
        9:00 AM - 9:30 AM: Welcome & Coffee
        9:30 AM - 10:30 AM: Q4 Performance Review
        10:30 AM - 10:45 AM: Break
        10:45 AM - 11:30 AM: 2025 Strategy Discussion
        11:30 AM - 12:00 PM: Action Items & Next Steps

        Please bring your laptop and any relevant materials.

        Security Notice:
        You will need to check in at the Apple Park Visitor Center.
        Please bring government-issued photo ID.
      DESC
      location: "Apple Park, 1 Apple Park Way, Cupertino, CA 95014",
      url: "https://example.com/meeting-details",
      timezone: "America/Los_Angeles",
      attendees: ["attendee@example.com"],
      show_attendees: true,
      notes: "Parking available at the Steve Jobs Theater parking structure."
    )
  end
end
