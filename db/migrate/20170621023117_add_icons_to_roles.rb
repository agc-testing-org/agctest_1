class AddIconsToRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :roles, :fa_icon, :string, :null => false
    remove_column :roles, :updated_at
    begin
        Role.find_by(name: "design").update(:fa_icon => "fa-paint-brush")
        Role.find_by(name: "development").update(:fa_icon => "fa-magic")
        Role.find_by(name: "product").update(:fa_icon => "fa-street-view")
        Role.find_by(name: "quality").update(:fa_icon => "fa-signal")
    rescue => e
        puts e
    end
  end
end
