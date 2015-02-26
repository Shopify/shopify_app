class AddToShops < ActiveRecord::Migration
  def self.up
    change_table :shops  do |t|
<% config[:new_columns].values.each do |column| -%>
      <%= column %>
<% end -%>
    end
<% config[:new_indexes].values.each do |index| -%>
    <%= index %>
<% end -%>
  end

  def self.down
    change_table :shops do |t|
<% if config[:new_columns].any? -%>
      t.remove <%= new_columns.keys.map { |column| ":#{column}" }.join(",") %>
<% end -%>
    end
  end
end
