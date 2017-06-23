class RemoveAfter < ActiveRecord::Migration[5.1]
  def change
    remove_column :sprint_timelines, :after
  end
end
