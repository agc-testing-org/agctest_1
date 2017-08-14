class JobInfo < ActiveRecord::Migration[5.1]
    def change
        add_column :jobs, :zip, :string, :null => false
        add_column :jobs, :company, :string, :null => false
    end
end
