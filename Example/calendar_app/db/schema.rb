# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_09_123149) do
  create_table "meeting_attendees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "meeting_id", null: false
    t.string "name"
    t.string "partstat", default: "needs_action", null: false
    t.datetime "updated_at", null: false
    t.index ["meeting_id", "email"], name: "index_meeting_attendees_on_meeting_id_and_email", unique: true
    t.index ["meeting_id"], name: "index_meeting_attendees_on_meeting_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_time", null: false
    t.string "location"
    t.string "organizer_email", null: false
    t.string "organizer_name", null: false
    t.integer "sequence", default: 0, null: false
    t.datetime "start_time", null: false
    t.string "status", default: "confirmed", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "title", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index ["uid"], name: "index_meetings_on_uid", unique: true
  end

  add_foreign_key "meeting_attendees", "meetings"
end
