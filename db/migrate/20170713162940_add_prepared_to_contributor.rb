class AddPreparedToContributor < ActiveRecord::Migration[5.1]
  def change
    add_column :contributors, :prepared, :boolean, :null => true
    add_column :contributors, :preparing, :boolean, :null => true
  end
end
