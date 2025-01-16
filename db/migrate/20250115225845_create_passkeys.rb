class CreatePasskeys < ActiveRecord::Migration[8.0]
  def change
    create_table :passkeys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nickname
      t.string :public_key
      t.integer :sign_count, default: 0, null: false
      t.string :external_id

      t.timestamps
    end
  end
end
