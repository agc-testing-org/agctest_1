class AddHiringManagerRecruiter < ActiveRecord::Migration[5.1]
    def change
        add_column :roles, :description, :string, :null => true
        Role.reset_column_information
        Role.create(name: "management", :fa_icon => "fa-puzzle-piece", :description => "I have the authority to hire")
        Role.create(name: "recruiting", :fa_icon => "fa-wifi", :description => "I help place talent")
        add_column :plans, :period, :integer, :default => 30, :null => false
        add_column :teams, :company, :string, :null => false
        add_column :user_teams, :job_id, :integer, :null => true
        remove_column :jobs, :company, :string

        add_foreign_key :user_teams, :jobs
        add_foreign_key :user_teams, :users, :column => :profile_id
        begin
            Plan.find_by(:name => "recruiter").update_attributes!(:description => "track and represent (as proxy) invited talent", :period => 90)
            Plan.find_by(:name => "manager").update_attributes!(:description => "post job listings and exclusively evaluate invited talent", :period => 30)
        rescue => e

        end
    end
end
