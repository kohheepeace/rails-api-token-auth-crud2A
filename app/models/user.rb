class User < ApplicationRecord
  has_secure_password
  has_secure_token

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :token, uniqueness: true

  has_many :posts
end
