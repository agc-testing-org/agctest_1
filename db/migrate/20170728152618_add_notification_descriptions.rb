class AddNotificationDescriptions < ActiveRecord::Migration[5.1]
    def change
        add_column :notifications, :description, :string, :null => false
        Notification.find_by(:name => "new").update_attributes({:description => "new sprint (feature, bug, or task request) created"})
        Notification.find_by(:name => "transition").update_attributes({:description => "sprint state change that corresponds with your role subscriptions"})
        Notification.find_by(:name => "comment").update_attributes({:description => "comment received for conversations that you're a part of through a vote, comment, or solution proposal, or where you created the sprint idea"})
        Notification.find_by(:name => "vote").update_attributes({:description => "vote received for conversations that you're a part of through a vote, comment, or solution proposal, or where you created the sprint idea"})
        Notification.find_by(:name => "winner").update_attributes({:description => "winning proposal selected for conversations that you're a part of through a vote, comment, or solution proposal, participation in a sprint phase, or where you created the sprint idea"})
    end
end
