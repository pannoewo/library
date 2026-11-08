class Loan < ApplicationRecord
  belongs_to :book
  belongs_to :reader

  before_validation :set_due_at, on: :create

  validates :borrowed_at, :due_at, presence: true
  validates :book_id,
    uniqueness: {
      conditions: -> { where(returned_at: nil) },
      message: "is already borrowed"
    },
    if: :active?

  def active?
    returned_at.nil?
  end

  private

  def set_due_at
    self.due_at = borrowed_at + 30.days if borrowed_at.present?
  end
end