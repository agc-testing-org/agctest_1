class AddSeatsToTeams < ActiveRecord::Migration[4.2]
    def change

        create_table "seats", force: :cascade do |t|
            t.string  "name", null: false
            t.datetime "created_at", null: false
        end

        Seat.create(name: "owner")
        Seat.create(name: "member")
        Seat.create(name: "free agent")
        Seat.create(name: "sponsored")
        Seat.create(name: "priority")

        create_table "plans", force: :cascade do |t|
            t.string  "name", null: false 
            t.string "title", null: false
            t.string "description", null: false
            t.string "seat_id", null: false
            t.datetime "created_at", null: false
        end                                         

        Plan.create(:name => "recruiter", :seat_id => Seat.find_by(:name => "sponsored").id, :title => "external recruiters", :description => "your team acts as a proxy for talent it invites")
        Plan.create(:name => "manager", :seat_id => Seat.find_by(:name => "priority").id, :title => "hiring managers and internal recruiters", :description => "your team has exclusive access to talent that it invites for a specified period of time")

        add_column :user_teams, :seat_id, :integer, :null => true
        add_column :user_teams, :period, :integer, :null => true

        add_column :teams, :plan_id, :integer, :null => false, :default => Plan.find_by(:name => "manager").id

        if ENV['INTEGRATIONS_INITIAL_USER_EMAIL']

            User.create(:email => ENV['INTEGRATIONS_INITIAL_USER_EMAIL'], :admin => true, :confirmed => true)
            initial_user_id = User.find_by(:email => ENV['INTEGRATIONS_INITIAL_USER_EMAIL'] ).id

        end 

        add_foreign_key "teams", "plans", column: "plan_id"

    end
end
