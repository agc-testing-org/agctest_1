class AddProviderEndpoints < ActiveRecord::Migration
    def change
        add_column :providers, :endpoint, :text, :null => true
    end
end
