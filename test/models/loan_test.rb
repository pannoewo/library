require "test_helper"

class LoanTest < ActiveSupport::TestCase
  test "rejects a second active loan through validation" do
    existing_loan = create(:loan)
    loan = build(:loan, book: existing_loan.book)

    assert_no_difference "Loan.count" do
      assert_not loan.save
    end

    assert loan.errors.of_kind?(:book_id, :taken)
    assert_includes loan.errors.full_messages, "Book is already borrowed"
  end

  test "allows updating the same active loan" do
    loan = create(:loan)

    assert loan.update(due_at: loan.due_at + 1.day)
  end

  test "allows a returned loan in the history of a currently borrowed book" do
    active_loan = create(:loan)
    historical_loan = build(:loan, book: active_loan.book, returned_at: 1.hour.ago)

    assert historical_loan.save
  end

  test "allows borrowing the book again after its return" do
    previous_loan = create(:loan, returned_at: 1.hour.ago)
    loan = build(:loan, book: previous_loan.book)

    assert loan.save
  end
end
