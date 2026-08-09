# frozen_string_literal: true

# Sends real RFC 5545 meeting requests/cancellations for a Meeting record.
#
# The two things that must agree for Gmail/Outlook/Apple Mail to render
# Accept/Decline actions (or process a cancellation) instead of a plain
# attachment: the METHOD inside the .ics content, and the `method=` parameter
# on the attachment's Content-Type header. See CONFIGURATION.md's "Email
# meeting invites (RSVP-capable)".
class MeetingMailer < ApplicationMailer
  def invite(meeting, method: :request)
    @meeting = meeting

    content = meeting.to_cal_event.generate_calendar_url(:ics, method: method)

    attachments["meeting.ics"] = {
      mime_type: "text/calendar; method=#{method.to_s.upcase}",
      content: content
    }

    mail(
      to: meeting.meeting_attendees.map(&:email),
      from: meeting.organizer_email,
      subject: method == :cancel ? "Cancelled: #{meeting.title}" : meeting.title
    )
  end
end
