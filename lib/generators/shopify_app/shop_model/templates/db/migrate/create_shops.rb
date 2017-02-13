class CreateShops < ActiveRecord::Migration
  def self.up
    create_table :shops  do |t|
      t.string  :shopify_domain, null: false
      t.string  :shopify_token, null: false
      t.integer :associated_user_id
      t.text    :extra_json
      t.timestamps
    end

    add_index :shops, [:shopify_domain, :associated_user_id], unique: true, name: 'shopify_user'
  end

  def self.down
    drop_table :shops
  end
end
