# frozen_string_literal: true

# Demonstrates the persistence CalInvite itself doesn't provide: a stable
# per-invite `uid` and a `sequence` counter, both required to send a
# `:request` update or a `:cancel` that mail clients recognize as referring
# to a previously sent invite rather than a new, unrelated event.
# See CONFIGURATION.md's "Updating and cancelling invites".
class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.string :title, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :location
      t.string :video_url
      t.text :description
      t.string :timezone, null: false, default: "UTC"
      t.string :organizer_name, null: false
      t.string :organizer_email, null: false

      # CalInvite::Event#uid / #sequence — persisted so a reschedule or
      # cancellation can reuse them instead of minting a new, unrelated event.
      t.string :uid, null: false
      t.integer :sequence, null: false, default: 0

      t.string :status, null: false, default: "confirmed" # confirmed | cancelled

      t.timestamps
    end

    add_index :meetings, :uid, unique: true
  end
end
