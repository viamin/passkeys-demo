class AddAuthenticatorAttachmentToPasskeys < ActiveRecord::Migration[8.0]
  def change
    add_column :passkeys, :authenticator_attachment, :string
  end
end
