class AddProcessing < ActiveRecord::Migration[5.1]
  def change
    add_column :sprint_timelines, :processing, :integer, :null => true
  end
end
