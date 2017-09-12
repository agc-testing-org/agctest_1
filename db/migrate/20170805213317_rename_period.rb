class RenamePeriod < ActiveRecord::Migration[5.1]
    def change
        rename_column :user_teams, :period, :expires
        change_column :user_teams, :expires, :datetime
    end
end