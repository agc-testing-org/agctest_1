class CreateStateRoles < ActiveRecord::Migration[5.1]
    def change
        create_table "role_states", force: :cascade do |t|
            t.integer  "role_id",       limit: 4,   null: false
            t.integer  "state_id",      limit: 4, null: false
            t.datetime "created_at",             null: false
        end
        begin 
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
        rescue => e
            puts e
        end
        add_foreign_key "role_states", "roles", column: "role_id"
        add_foreign_key "role_states", "states", column: "state_id"

    end
end
