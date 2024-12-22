# frozen_string_literal: true

# app/mailers/calendar_invite_mailer.rb
class CalendarInviteMailer < ApplicationMailer
  def event_invitation(event)
    @event = event

    # Generate ICS file content
    ics_content = CalInvite::Providers::Ics.new(event).generate

    # Attach ICS file
    attachments['event.ics'] = {
      mime_type: 'text/calendar',
      content: ics_content
    }

    mail(
      to: @event.attendees,
      subject: @event.title,
      content_type: "text/html"
    )
  end
end
