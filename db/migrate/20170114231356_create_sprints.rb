class CreateSprints < ActiveRecord::Migration[4.2]
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

        Label.create("name": "needs-owner")

        create_table "states", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.string   "fa_icon",       limit: 255, null: false
            t.string   "description",       limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
            t.text "instruction", null: false
            t.boolean "contributors", null: false, default: false 
        end

        State.create("name": "idea", "fa_icon": "fa-lightbulb-o", "description": "introduction of a new feature proposal, task, or bug", "contributors": false, "instruction": "This is awaiting prioritization.")
        State.create("name": "requirements design", "fa_icon": "fa-location-arrow", "description": "definition of requirements / specifications",  "contributors": true, "instruction": "Show us how you would provide requirements for this idea.")
        State.create("name": "requirements review", "fa_icon": "fa-globe", "description": "review of specifications",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the requirements proposals above for this idea before any implementation begins.  We will reopen the stage if other proposals are needed.")
        State.create("name": "visual design", "fa_icon": "fa-paint-brush", "description": "user interface / experience design",  "contributors": true, "instruction": "Propose a slick design or assets for this idea.")
        State.create("name": "design review", "fa_icon": "fa-globe", "description": "review of user interface / experience",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the design proposals above for this idea before development begins.  We will reopen the stage if other proposals are needed.")
        State.create("name": "development", "fa_icon": "fa-code", "description": "technical implementation of requirements",  "contributors": true, "instruction": "Propose a solution that makes this idea come alive!")
        State.create("name": "development review", "fa_icon": "fa-globe", "description": "review of technical implementation",  "contributors": false, "instruction": "This is your chance to provide feedback (through comments and votes) on the technical implementations above for this idea.  We will reopen the stage if other proposals are needed.")
        State.create("name": "closed", "fa_icon": "fa-thumbs-o-up", "description": "completion of an idea",  "contributors": false, "instruction": "We have moved on from this idea but contributor feedback is always welcome.")

        create_table "user_skillsets", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "skillset_id",   limit: 4,                null: false
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
            t.boolean  "active",               default: true, null: false
        end

        add_index "user_skillsets", ["skillset_id"]
        add_index "user_skillsets", ["user_id"]


        create_table "projects", force: :cascade do |t|
            t.string  "org",       limit: 255, null: false
            t.string  "name",       limit: 255,                 null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        create_table "sprints", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                   null: false
            t.integer   "project_id",       limit: 4,                 null: false
            t.string "title", limit: 255
            t.text "description"
            t.datetime "created_at",                             null: false
            t.datetime "updated_at",                             null: false
            t.datetime "deadline"
            t.string   "sha",        limit: 255,                 null: true 
        end

        add_index "sprints", ["user_id"]
        add_index "sprints", ["project_id"]

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
        add_foreign_key "sprints", "projects", column: "project_id"
        add_foreign_key "user_skillsets", "skillsets", column: "skillset_id"
        add_foreign_key "user_skillsets", "users", column: "user_id"
        add_foreign_key "sprint_skillsets", "skillsets", column: "skillset_id"
        add_foreign_key "sprint_skillsets", "sprints", column: "sprint_id"

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
