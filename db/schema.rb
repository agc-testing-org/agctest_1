# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 201706161200001) do

  create_table "comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "sprint_state_id", null: false
    t.integer "comment_id"
    t.integer "contributor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "text", null: false
    t.index ["contributor_id"], name: "fk_rails_a1385053cc"
    t.index ["sprint_state_id"], name: "index_comments_on_sprint_state_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connection_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
  end

  create_table "contributors", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "sprint_state_id", null: false
    t.string "repo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commit"
    t.string "commit_remote"
    t.boolean "commit_success"
    t.integer "insertions"
    t.integer "deletions"
    t.integer "lines"
    t.integer "files"
    t.string "project_id", null: false
    t.index ["sprint_state_id"], name: "index_contributors_on_sprint_state_id"
    t.index ["user_id"], name: "index_contributors_on_user_id"
  end

  create_table "labels", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "logins", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.string "ip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ip"], name: "index_logins_on_ip"
    t.index ["user_id"], name: "index_logins_on_user"
  end

  create_table "notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "subject", null: false
    t.text "body", limit: 255, null: false
    t.integer "sprint_state_id"
    t.integer "contributor_id"
    t.integer "user_id"
    t.integer "sprint_timeline_id", null: false
    t.integer "sprint_id", null: false
    t.string "project_org", null: false
    t.datetime "created_at", null: false
    t.string "sprint_name", null: false
    t.string "project_name", null: false
    t.integer "project_id", null: false
    t.text "comment_body"
    t.index ["sprint_timeline_id"], name: "index_sprint_timeline_id_on_notification", unique: true
  end

  create_table "plans", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "title", null: false
    t.string "description", null: false
    t.string "seat_id", null: false
    t.datetime "created_at", null: false
  end

  create_table "projects", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "org", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.string "fa_icon", null: false
  end

  create_table "seats", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
  end

  create_table "skillsets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sprint_skillsets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "skillset_id", null: false
    t.integer "sprint_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["skillset_id"], name: "index_sprint_skillsets_on_skillset_id"
    t.index ["sprint_id"], name: "index_sprint_skillsets_on_sprint_id"
  end

  create_table "sprint_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "sprint_id", null: false
    t.integer "state_id", null: false
    t.datetime "deadline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contributor_id"
    t.string "sha"
    t.integer "arbiter_id"
    t.boolean "merged"
    t.integer "pull_request"
    t.index ["arbiter_id"], name: "fk_rails_a961915d3b"
    t.index ["contributor_id"], name: "fk_rails_52fb9ef0eb"
    t.index ["sprint_id"], name: "index_sprint_states_on_sprint_id"
    t.index ["state_id"], name: "fk_rails_bececa531a"
  end

  create_table "sprint_timelines", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "sprint_id", null: false
    t.integer "state_id"
    t.integer "label_id"
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.integer "user_id", null: false
    t.integer "after"
    t.integer "comment_id"
    t.integer "sprint_state_id"
    t.integer "vote_id"
    t.integer "contributor_id"
    t.string "diff", null: false
    t.integer "processed", default: 0
    t.index ["comment_id"], name: "fk_rails_1251c5b8fd"
    t.index ["contributor_id"], name: "fk_rails_c3269fa3ec"
    t.index ["label_id"], name: "fk_rails_1b320ef958"
    t.index ["sprint_id"], name: "index_sprint_timelines_on_sprint_id"
    t.index ["sprint_state_id"], name: "fk_rails_e755d52f56"
    t.index ["state_id"], name: "fk_rails_c9feeeb84f"
    t.index ["vote_id"], name: "fk_rails_9f8155a22b"
  end

  create_table "sprints", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deadline"
    t.string "sha"
    t.index ["project_id"], name: "index_sprints_on_project_id"
    t.index ["user_id"], name: "index_sprints_on_user_id"
  end

  create_table "states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "fa_icon", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "instruction", null: false
    t.boolean "contributors", default: false, null: false
  end

  create_table "teams", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "plan_id", default: 2, null: false
    t.index ["plan_id"], name: "fk_rails_fe85bf605a"
  end

  create_table "user_connections", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "contact_id", null: false
    t.integer "confirmed", default: 1
    t.boolean "read", default: false
    t.string "user_name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["contact_id"], name: "index_user_connections_on_contact_id"
    t.index ["user_id", "contact_id"], name: "index_contact_id_and_user_id_on_user_connections", unique: true
    t.index ["user_id"], name: "index_user_connections_on_user_id"
  end

  create_table "user_contributors", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "contributors_id", null: false
    t.index ["user_id", "contributors_id"], name: "index_contributors_id_and_user_id_on_user_contributor", unique: true
  end

  create_table "user_notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.boolean "read", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "sprint_timeline_id", null: false
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "user_positions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_profile_id", null: false
    t.string "title"
    t.string "size"
    t.integer "start_year"
    t.integer "end_year"
    t.string "company"
    t.string "industry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "fk_rails_a62e6232fa"
  end

  create_table "user_profiles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.string "headline"
    t.string "location_country_code"
    t.string "location_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "fk_rails_87a6352e58"
  end

  create_table "user_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.index ["role_id"], name: "fk_rails_3369e0d5fc"
    t.index ["user_id"], name: "index_user_roles_on_user"
  end

  create_table "user_skillsets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "skillset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["skillset_id"], name: "index_user_skillsets_on_skillset_id"
    t.index ["user_id"], name: "index_user_skillsets_on_user_id"
  end

  create_table "user_teams", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id"
    t.integer "sender_id", null: false
    t.string "user_email"
    t.integer "team_id", null: false
    t.boolean "accepted", default: false
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "seat_id"
    t.integer "period"
    t.index ["sender_id"], name: "fk_rails_58c1498938"
    t.index ["team_id"], name: "fk_rails_64c25f3fe6"
    t.index ["user_id"], name: "index_user_team_on_user"
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "email", null: false
    t.string "first_name"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "jwt"
    t.string "ip"
    t.boolean "lock", default: false
    t.boolean "protected", default: false
    t.string "password"
    t.boolean "confirmed", default: false
    t.string "token"
    t.string "github_username"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "votes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "user_id", null: false
    t.integer "sprint_state_id", null: false
    t.integer "comment_id"
    t.integer "contributor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contributor_id"], name: "fk_rails_ef3485c16e"
    t.index ["sprint_state_id"], name: "index_votes_on_sprint_state_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "comments", "contributors"
  add_foreign_key "comments", "sprint_states"
  add_foreign_key "comments", "users"
  add_foreign_key "contributors", "sprint_states"
  add_foreign_key "contributors", "users"
  add_foreign_key "logins", "users"
  add_foreign_key "sprint_skillsets", "skillsets"
  add_foreign_key "sprint_skillsets", "sprints"
  add_foreign_key "sprint_states", "contributors"
  add_foreign_key "sprint_states", "sprints"
  add_foreign_key "sprint_states", "states"
  add_foreign_key "sprint_states", "users", column: "arbiter_id"
  add_foreign_key "sprint_timelines", "comments"
  add_foreign_key "sprint_timelines", "contributors"
  add_foreign_key "sprint_timelines", "labels"
  add_foreign_key "sprint_timelines", "sprint_states"
  add_foreign_key "sprint_timelines", "sprints"
  add_foreign_key "sprint_timelines", "states"
  add_foreign_key "sprint_timelines", "votes"
  add_foreign_key "sprints", "projects"
  add_foreign_key "sprints", "users"
  add_foreign_key "teams", "plans"
  add_foreign_key "user_positions", "user_profiles"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_skillsets", "skillsets"
  add_foreign_key "user_skillsets", "users"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
  add_foreign_key "user_teams", "users", column: "sender_id"
  add_foreign_key "votes", "contributors"
  add_foreign_key "votes", "sprint_states"
  add_foreign_key "votes", "users"
end
