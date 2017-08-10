class UpdateStateInstructions < ActiveRecord::Migration[5.1]
  def change
    State.find_by({:name => "idea"}).update_attributes!({:description => "introduction of a new feature or improvement"})
    State.find_by({:name => "requirements review"}).update_attributes!({:instruction => "This is your chance to provide feedback (through comments and votes) on requirements proposals for this idea before implementation begins."})
    State.find_by({:name => "design review"}).update_attributes!({:instruction => "This is your chance to provide feedback (through comments and votes) on design proposals for this idea before development begins."})
    State.find_by({:name => "development review"}).update_attributes!({:instruction => "This is your chance to provide feedback (through comments and votes) on development proposals for this idea."})
  end
end
