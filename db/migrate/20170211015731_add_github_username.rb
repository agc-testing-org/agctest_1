class AddGithubUsername < ActiveRecord::Migration
  def change
    add_column :users, :github_username, :string, :null => true
  end
end
