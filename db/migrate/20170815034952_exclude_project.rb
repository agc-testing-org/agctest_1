class ExcludeProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :hidden, :integer, :null => true
  end
end
