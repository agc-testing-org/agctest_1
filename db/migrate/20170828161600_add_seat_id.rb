class AddSeatId < ActiveRecord::Migration[5.1]
    def change
        add_column :user_connections, :seat_id, :integer
    end
end