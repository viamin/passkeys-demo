class AddPasskeyIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :passkey_id, :string
  end
end
