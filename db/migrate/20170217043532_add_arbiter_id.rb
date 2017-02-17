class AddArbiterId < ActiveRecord::Migration
    def change
        rename_column :sprint_states, :user_id, :contributor_id
        add_column :sprint_states, :arbiter_id, :integer, :null => true
        add_foreign_key "sprint_states", "contributors", column: "contributor_id"
        add_foreign_key "sprint_states", "users", column: "arbiter_id"
    end
end
