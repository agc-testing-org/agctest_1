class AddEmberToSkills < ActiveRecord::Migration[5.1]
  def change
    Skillset.create("name": "Ember")
  end
end
