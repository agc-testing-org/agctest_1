class AddRoleToJob < ActiveRecord::Migration[5.1]
  def change
    add_column :jobs, :role_id, :integer, :null => false
  end
end
