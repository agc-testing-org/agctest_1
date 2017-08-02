class AddListing < ActiveRecord::Migration[5.1]
    def change
        create_table "jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "user_id", null: false
            t.integer "team_id", null: false
            t.text "link", null: false
            t.text "title", null: false
            t.boolean "open", default: true
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.index ["team_id"], name: "index_jobs_on_team_id"
            t.index ["open"], name: "index_jobs_on_open"
            t.index ["user_id"], name: "index_jobs_on_user_id"
        end
        add_foreign_key :jobs, :users
        add_foreign_key :jobs, :teams

        add_column :sprints, :job_id, :integer, :null => true
        add_foreign_key :sprints, :jobs

        change_column :sprint_timelines, :project_id, :integer, :null => true
        change_column :sprint_timelines, :sprint_id, :integer, :null => true
        add_column :sprint_timelines, :job_id, :integer, :null => true
        add_foreign_key :sprint_timelines, :jobs
    end
end
