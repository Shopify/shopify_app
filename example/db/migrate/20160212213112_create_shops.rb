class CreateShops < ActiveRecord::Migration
  def change
    create_table :shops  do |t|
      t.string :shopify_domain, null: false, limit: 255
      t.string :shopify_token, null: false, limit: 255
      t.timestamps null: false
    end

    add_index :shops, :shopify_domain, unique: true
  end
end
