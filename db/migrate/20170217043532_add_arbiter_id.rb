class AddArbiterId < ActiveRecord::Migration
    def change
        add_column :sprint_states, :arbiter_id, :integer, :null => true
        add_foreign_key "sprint_states", "users", column: "user_id"
        add_foreign_key "sprint_states", "users", column: "arbiter_id"
    end
end
