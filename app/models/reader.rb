require "uri"

class Reader < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error, inverse_of: :reader

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :library_card_number,
    presence: true,
    uniqueness: true,
    format: { with: /\A\d{6}\z/ }
  validates :full_name, presence: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
