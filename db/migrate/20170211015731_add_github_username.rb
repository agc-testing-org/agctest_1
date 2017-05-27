class AddGithubUsername < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :github_username, :string, :null => true
  end
end
