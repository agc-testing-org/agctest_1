class PrivateReview < ActiveRecord::Migration[5.1]
    def change
        Notification.create("name": "peer review", "description": "review of other solution proposals before inviting all users for feedback")    
    end
end
