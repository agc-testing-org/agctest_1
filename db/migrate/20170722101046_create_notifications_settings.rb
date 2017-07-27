class CreateNotificationsSettings < ActiveRecord::Migration[5.1]
	def up
		create_table "user_notification_settings", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
			t.integer "user_id", null: false
            t.integer "notification_id", null: false
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
            t.boolean "active", default: true, null: false
            t.index ["notification_id"], name: "index_user_notification_settings_on_notification_id"
            t.index ["user_id"], name: "index_user_notification_settings_on_user_id"
        end
    end
end
