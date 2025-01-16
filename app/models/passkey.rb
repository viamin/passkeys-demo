class Passkey < ApplicationRecord
  belongs_to :user

  validates :external_id, :public_key, :sign_count, :nickname, presence: true
  validates :external_id, uniqueness: true
  validates :sign_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
