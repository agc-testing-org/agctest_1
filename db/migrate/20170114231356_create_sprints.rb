class CreateSprints < ActiveRecord::Migration
    def change

        create_table "skillsets", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

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

        create_table "labels", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        Label.create("name": "needs-spec")
        Label.create("name": "needs-design")
        Label.create("name": "needs-developer")
        Label.create("name": "needs-review")
        Label.create("name": "needs-decision")
        Label.create("name": "needs-testing")

        create_table "states", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        State.create("name": "idea")
        State.create("name": "backlog")
        State.create("name": "in-progress")
        State.create("name": "resolved")
        State.create("name": "closed")

        create_table "user_skillsets", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "skillset_id",   limit: 4,                null: false
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
            t.boolean  "active",               default: true, null: false
        end

        add_index "user_skillsets", ["skillset_id"]
        add_index "user_skillsets", ["user_id"]

        create_table "sprints", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                   null: false
            t.string   "repo",       limit: 255,                 null: false
            t.string "title", limit: 255
            t.text "description"
            t.datetime "created_at",                             null: false
            t.datetime "updated_at",                             null: false
            t.datetime "deadline"
            t.string   "sha",        limit: 255,                 null: false
            t.string   "org",        limit: 255,                 null: false
            t.integer  "winner_id",     limit: 4
        end

        add_index "sprints", ["user_id"]
        add_index "sprints", ["repo"]
        add_index "sprints", ["winner_id"]

        create_table "sprint_skillsets", force: :cascade do |t|
            t.integer  "skillset_id",   limit: 4,                null: false
            t.integer  "sprint_id",   limit: 4,                null: false
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
            t.boolean  "active",               default: true, null: false
        end

        add_index "sprint_skillsets", ["skillset_id"]
        add_index "sprint_skillsets", ["sprint_id"]

        add_foreign_key "sprints", "users", column: "user_id"
        add_foreign_key "user_skillsets", "skillsets", column: "skillset_id"
        add_foreign_key "user_skillsets", "users", column: "user_id"
        add_foreign_key "sprint_skillsets", "skillsets", column: "skillset_id"
        add_foreign_key "sprint_skillsets", "sprints", column: "sprint_id"

        create_table "contributors", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,   null: false
            t.integer  "sprint_id",         limit: 4,   null: false
            t.string   "repo",           limit: 255, null: false
            t.datetime "created_at",                 null: false
            t.datetime "updated_at",                 null: false
            t.string   "commit",         limit: 255
            t.string   "commit_remote",  limit: 255
            t.boolean  "commit_success"
            t.integer  "insertions",     limit: 4
            t.integer  "deletions",      limit: 4
            t.integer  "lines",          limit: 4
            t.integer  "files",          limit: 4
        end

        add_index "contributors", ["sprint_id"]
        add_foreign_key "contributors", "users", column: "user_id"
        add_foreign_key "contributors", "sprints", column: "sprint_id"

        create_table "sprint_timelines", force: :cascade do |t|
            t.integer  "sprint_id",     limit: 4,                 null: false
            t.integer  "state_id", limit: 4, null: true
            t.integer  "label_id", limit: 4, null: true
            t.datetime "created_at",                           null: false
        end

        add_index "sprint_timelines", ["sprint_id"]
        add_foreign_key "sprint_timelines", "sprints", column: "sprint_id"
        add_foreign_key "sprint_timelines", "states", column: "state_id"
        add_foreign_key "sprint_timelines", "labels", column: "label_id"

    end
end
