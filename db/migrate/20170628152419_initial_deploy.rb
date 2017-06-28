class InitialDeploy < ActiveRecord::Migration[5.1]
    def change
        create_table "comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "sprint_state_id", null: false
            t.integer "contributor_id"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.text "text", null: false
            t.index ["contributor_id"], name: "index_comments_on_contributor_id"
            t.index ["sprint_state_id"], name: "index_comments_on_sprint_state_id"
            t.index ["user_id"], name: "index_comments_on_user_id"
        end

        add_foreign_key "comments", "contributors"
        add_foreign_key "comments", "sprint_states"
        add_foreign_key "comments", "users"

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
            t.index ["sprint_state_id"], name: "index_contributors_on_sprint_state_id"
            t.index ["user_id"], name: "index_contributors_on_user_id"
        end

        add_foreign_key "contributors", "sprint_states"
        add_foreign_key "contributors", "users"

        create_table "logins", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.string "ip", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["ip"], name: "index_logins_on_ip"
            t.index ["user_id"], name: "index_logins_on_user"
        end

        add_foreign_key "logins", "users"

        create_table "plans", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.string "name", null: false
            t.string "title", null: false
            t.string "description", null: false
            t.string "seat_id", null: false
            t.datetime "created_at", null: false
        end

        create_table "projects", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.string "org", null: false
            t.string "name", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
        end

        create_table "role_states", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "role_id", null: false
            t.integer "state_id", null: false
            t.datetime "created_at", null: false
        end

        add_foreign_key "role_states", "roles"
        add_foreign_key "role_states", "states"

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

        add_foreign_key "sprint_skillsets", "skillsets"
        add_foreign_key "sprint_skillsets", "sprints"

        create_table "sprint_states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "sprint_id", null: false
            t.integer "state_id", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.integer "contributor_id"
            t.string "sha"
            t.integer "arbiter_id"
            t.boolean "merged"
            t.integer "pull_request"
            t.index ["arbiter_id"], name: "index_sprint_states_on_arbiter_id"
            t.index ["contributor_id"], name: "index_sprint_states_on_contributor_id"
            t.index ["sprint_id"], name: "index_sprint_states_on_sprint_id"
            t.index ["state_id"], name: "index_sprint_states_on_state_id"
        end

        add_foreign_key "sprint_states", "contributors"
        add_foreign_key "sprint_states", "sprints"
        add_foreign_key "sprint_states", "states"
        add_foreign_key "sprint_states", "users", column: "arbiter_id"

        create_table "sprint_timelines", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "sprint_id", null: false
            t.integer "state_id"
            t.datetime "created_at", null: false
            t.integer "project_id", null: false
            t.integer "user_id", null: false
            t.integer "comment_id"
            t.integer "sprint_state_id"
            t.integer "vote_id"
            t.integer "contributor_id"
            t.string "diff", null: false
            t.integer "processed", default: 0
            t.integer "processing"
            t.integer "next_sprint_state_id"
            t.index ["comment_id"], name: "index_sprint_timelines_on_comment_id"
            t.index ["contributor_id"], name: "index_sprint_timelines_on_contributor_id"
            t.index ["sprint_id"], name: "index_sprint_timelines_on_sprint_id"
            t.index ["sprint_state_id"], name: "index_sprint_timelines_on_sprint_state_id"
            t.index ["state_id"], name: "index_sprint_timelines_on_state_id"
            t.index ["vote_id"], name: "index_sprint_timelines_on_vote_id"
            t.index ["project_id"], name: "index_sprint_timelines_on_project_id"
        end

        add_foreign_key "sprint_timelines", "comments"
        add_foreign_key "sprint_timelines", "contributors"
        add_foreign_key "sprint_timelines", "sprint_states"
        add_foreign_key "sprint_timelines", "sprints"
        add_foreign_key "sprint_timelines", "states"
        add_foreign_key "sprint_timelines", "votes"
        add_foreign_key "sprint_timelines", "projects" 

        create_table "sprints", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "project_id", null: false
            t.string "title"
            t.text "description"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["project_id"], name: "index_sprints_on_project_id"
            t.index ["user_id"], name: "index_sprints_on_user_id"
        end

        add_foreign_key "sprints", "projects"
        add_foreign_key "sprints", "users"

        create_table "states", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.string "name", null: false
            t.string "fa_icon", null: false
            t.string "description", null: false
            t.datetime "created_at", null: false
            t.text "instruction", null: false
            t.boolean "contributors", default: false, null: false
        end

        create_table "teams", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.string "name", null: false
            t.string "user_id", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.integer "plan_id", default: 2, null: false
            t.index ["plan_id"], name: "index_teams_on_plan_id"
            t.index ["user_id"], name: "index_teams_on_user_id"
        end
    
        add_foreign_key "teams", "plans"
        add_foreign_key "teams", "users"

        create_table "user_connections", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "contact_id", null: false
            t.integer "confirmed", default: 1
            t.boolean "read", default: false
            t.datetime "created_at"
            t.datetime "updated_at"
            t.index ["contact_id"], name: "index_user_connections_on_contact_id"
            t.index ["user_id", "contact_id"], name: "index_contact_id_and_user_id_on_user_connections", unique: true
            t.index ["user_id"], name: "index_user_connections_on_user_id"
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
            t.index ["user_profile_id"], name: "index_user_positions_on_user_profile_id"
        end
        
        add_foreign_key "user_positions", "user_profiles"

        create_table "user_profiles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.string "headline"
            t.string "location_country_code"
            t.string "location_name"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["user_id"], name: "index_user_profiles_on_user_id"
        end

        add_foreign_key "user_profiles", "users"

        create_table "user_roles", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "role_id", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.boolean "active", default: false
            t.index ["role_id"], name: "index_user_roles_on_role_id"
            t.index ["user_id"], name: "index_user_roles_on_user_id"
        end

        add_foreign_key "user_roles", "roles"
        add_foreign_key "user_roles", "users"

        create_table "user_skillsets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "skillset_id", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.boolean "active", default: true, null: false
            t.index ["skillset_id"], name: "index_user_skillsets_on_skillset_id"
            t.index ["user_id"], name: "index_user_skillsets_on_user_id"
        end

        add_foreign_key "user_skillsets", "skillsets"
        add_foreign_key "user_skillsets", "users"

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
            t.index ["sender_id"], name: "index_user_teams_on_sender_id"
            t.index ["team_id"], name: "index_user_teams_on_team_id"
            t.index ["user_id"], name: "index_user_teams_on_user_id"
            t.index ["token"], name: "index_user_teams_on_token", unique: true
        end

        add_foreign_key "user_teams", "teams"
        add_foreign_key "user_teams", "users"
        add_foreign_key "user_teams", "users", column: "sender_id"

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
            t.string "refresh"
            t.index ["email"], name: "index_users_on_email", unique: true
            t.index ["token"], name: "index_users_on_token", unique: true
            t.index ["refresh"], name: "index_users_on_refresh", unique: true
        end

        create_table "votes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "sprint_state_id", null: false
            t.integer "contributor_id"
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["contributor_id"], name: "index_votes_on_contributor_id"
            t.index ["sprint_state_id"], name: "index_votes_on_sprint_state_id"
            t.index ["user_id"], name: "index_votes_on_user_id"
        end

        add_foreign_key "votes", "contributors"
        add_foreign_key "votes", "sprint_states"
        add_foreign_key "votes", "users"


        Role.create(name: "product", :fa_icon => "fa-street-view")
        Role.create(name: "quality", :fa_icon => "fa-signal")
        Role.create(name: "development", :fa_icon => "fa-magic")
        Role.create(name: "design", :fa_icon => "fa-paint-brush")

        Skillset.create("name": "ActionScript")
        Skillset.create("name": "Angular")
        Skillset.create("name": "C")
        Skillset.create("name": "C#")
        Skillset.create("name": "C++")
        Skillset.create("name": "Chef")
        Skillset.create("name": "CSS")
        Skillset.create("name": "Clojure")
        Skillset.create("name": "CoffeeScript")
        Skillset.create("name": "Express.js")
        Skillset.create("name": "Go")
        Skillset.create("name": "HTML")
        Skillset.create("name": "Haskell")
        Skillset.create("name": "Java")
        Skillset.create("name": "JavaScript")
        Skillset.create("name": "Lua")
        Skillset.create("name": "Matlab")
        Skillset.create("name": "Objective-C")
        Skillset.create("name": "PHP")
        Skillset.create("name": "Perl")
        Skillset.create("name": "Python")
        Skillset.create("name": "R")
        Skillset.create("name": "Ruby")
        Skillset.create("name": "Ruby On Rails")
        Skillset.create("name": "Scala")
        Skillset.create("name": "Shell")
        Skillset.create("name": "Sinatra")
        Skillset.create("name": "Swift")
        Skillset.create("name": "TeX")
        Skillset.create("name": "VimL")

        State.create("name": "idea", "fa_icon": "fa-lightbulb-o", "description": "introduction of a new feature proposal, task, or bug", "contributors": false, "instruction": "This is awaiting prioritization.")
        State.create("name": "requirements design", "fa_icon": "fa-location-arrow", "description": "definition of requirements / specifications",  "contributors": true, "instruction": "Show us how you would provide requirements for this idea.")
        State.create("name": "requirements review", "fa_icon": "fa-globe", "description": "review of specifications",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the requirements proposals above for this idea before any implementation begins.  We will reopen the stage if other proposals are needed.")
        State.create("name": "visual design", "fa_icon": "fa-paint-brush", "description": "user interface / experience design",  "contributors": true, "instruction": "Propose a slick design or assets for this idea.")
        State.create("name": "design review", "fa_icon": "fa-globe", "description": "review of user interface / experience",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the design proposals above for this idea before development begins.  We will reopen the stage if other proposals are needed.")
        State.create("name": "development", "fa_icon": "fa-code", "description": "technical implementation of requirements",  "contributors": true, "instruction": "Propose a solution that makes this idea come alive!")
        State.create("name": "development review", "fa_icon": "fa-globe", "description": "review of technical implementation",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the technical implementations above for this idea.  We will reopen the stage if other proposals are needed.")
        State.create("name": "closed", "fa_icon": "fa-thumbs-o-up", "description": "completion of an idea",  "contributors": false, "instruction": "We have moved on from this idea but contributor feedback is always welcome.")

        RoleState.create(:role_id => Role.find_by(:name => "product").id, :state_id => State.find_by(:name => "requirements design").id)
        RoleState.create(:role_id => Role.find_by(:name => "product").id, :state_id => State.find_by(:name => "requirements review").id)
        RoleState.create(:role_id => Role.find_by(:name => "product").id, :state_id => State.find_by(:name => "design review").id)
        RoleState.create(:role_id => Role.find_by(:name => "product").id, :state_id => State.find_by(:name => "development review").id)

        RoleState.create(:role_id => Role.find_by(:name => "quality").id, :state_id => State.find_by(:name => "requirements review").id)
        RoleState.create(:role_id => Role.find_by(:name => "quality").id, :state_id => State.find_by(:name => "development review").id)

        RoleState.create(:role_id => Role.find_by(:name => "development").id, :state_id => State.find_by(:name => "requirements review").id)
        RoleState.create(:role_id => Role.find_by(:name => "development").id, :state_id => State.find_by(:name => "development").id)
        RoleState.create(:role_id => Role.find_by(:name => "development").id, :state_id => State.find_by(:name => "development review").id)

        RoleState.create(:role_id => Role.find_by(:name => "design").id, :state_id => State.find_by(:name => "requirements review").id)
        RoleState.create(:role_id => Role.find_by(:name => "design").id, :state_id => State.find_by(:name => "visual design").id)
        RoleState.create(:role_id => Role.find_by(:name => "design").id, :state_id => State.find_by(:name => "design review").id)
        RoleState.create(:role_id => Role.find_by(:name => "design").id, :state_id => State.find_by(:name => "development review").id)

        Seat.create(name: "owner")
        Seat.create(name: "member")
        Seat.create(name: "free agent")
        Seat.create(name: "sponsored")
        Seat.create(name: "priority")

        Plan.create(:name => "recruiter", :seat_id => Seat.find_by(:name => "sponsored").id, :title => "external recruiters", :description => "your team acts as a proxy for talent it invites")
        Plan.create(:name => "manager", :seat_id => Seat.find_by(:name => "priority").id, :title => "hiring managers and internal recruiters", :description => "your team has exclusive access to talent that it invites for a specified period of time")


        if ENV['INTEGRATIONS_INITIAL_USER_EMAIL']
            User.create(:email => ENV['INTEGRATIONS_INITIAL_USER_EMAIL'], :admin => true, :confirmed => true)
        end

    end
end
