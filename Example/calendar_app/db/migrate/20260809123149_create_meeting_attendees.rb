# frozen_string_literal: true

# Tracks per-attendee RSVP status. CalInvite doesn't track this itself — it
# only renders ATTENDEE lines from whatever partstat you give it. Populating
# `partstat` after the fact (from an inbound reply, a provider webhook, or a
# manual update) is entirely up to the host app. See CONFIGURATION.md's
# "Tracking RSVPs" section.
class CreateMeetingAttendees < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_attendees do |t|
      t.references :meeting, null: false, foreign_key: true
      t.string :email, null: false
      t.string :name

      # Mirrors CalInvite's attendee partstat: values.
      t.string :partstat, null: false, default: "needs_action"

      t.timestamps
    end

    add_index :meeting_attendees, [:meeting_id, :email], unique: true
  end
end
