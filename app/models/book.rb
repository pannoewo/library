class Book < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error, inverse_of: :book

  validates :serial_number,
    presence: true,
    uniqueness: true,
    format: { with: /\A\d{6}\z/ }
  validates :title, :author, presence: true

  def available?
    if loans.loaded?
      loans.none?(&:active?)
    else
      !loans.exists?(returned_at: nil)
    end
  end
end
