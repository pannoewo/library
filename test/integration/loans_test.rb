require "test_helper"

class LoansTest < ActionDispatch::IntegrationTest
  test "creates a loan from JSON parameters and returns JSON" do
    book = create(:book)
    reader = create(:reader)

    assert_difference "Loan.count", 1 do
      post loans_url, params: {
        loan: { book_id: book.id, reader_id: reader.id }
      }, as: :json
    end

    assert_response :created
    assert_equal "application/json", response.media_type
    assert_not book.reload.available?
  end

  test "creates a loan and marks its book unavailable" do
    book = create(:book)
    reader = create(:reader)
    requested_due_at = 1.week.from_now

    assert_difference "Loan.count", 1 do
      post loans_url, params: {
        loan: { book_id: book.id, reader_id: reader.id, due_at: requested_due_at }
      }, as: :json
    end

    assert_response :created
    loan = response.parsed_body
    assert_equal book.id, loan.fetch("book_id")
    assert_equal reader.id, loan.fetch("reader_id")
    borrowed_at = Time.iso8601(loan.fetch("borrowed_at"))
    due_at = Time.iso8601(loan.fetch("due_at"))
    assert_equal 30.days.to_i, (due_at - borrowed_at).to_i
    assert_nil loan.fetch("returned_at")
    assert_not book.reload.available?
  end

  test "does not create another active loan for a borrowed book" do
    book = create(:book)
    reader = create(:reader)
    create(:loan, book: book)

    assert_no_difference "Loan.count" do
      post loans_url, params: {
        loan: { book_id: book.id, reader_id: reader.id, due_at: 1.week.from_now }
      }, as: :json
    end

    assert_response :conflict
    assert_includes response.parsed_body.fetch("errors"), "Book is already borrowed"
  end

  test "returns validation errors when the reader is missing" do
    book = create(:book)

    assert_no_difference "Loan.count" do
      post loans_url, params: { loan: { book_id: book.id } }, as: :json
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors"), "Reader must exist"
    assert book.reload.available?
  end

  test "returns JSON bad request when loan parameters are missing" do
    post loans_url, params: {}, as: :json

    assert_response :bad_request
    assert_equal "application/json", response.media_type
    assert_not_empty response.parsed_body.fetch("errors")
  end

  test "returns a JSON error when returning a missing book" do
    patch return_book_url(book_id: 0)

    assert_response :not_found
    assert_equal "application/json", response.media_type
    assert_equal({ "errors" => [ "Book not found" ] }, response.parsed_body)
  end

  test "returns a conflict when the book is not borrowed" do
    book = create(:book)

    assert_no_difference "Loan.count" do
      patch return_book_url(book_id: book.id)
    end

    assert_response :conflict
    assert_equal({ "errors" => [ "Book is not currently borrowed" ] }, response.parsed_body)
  end

  test "returns the active loan by book id without changing borrowing history" do
    time_now = Time.current
    book = create(:book)
    previous_loan = create(:loan, book: book, borrowed_at: time_now - 2.weeks, returned_at: time_now - 1.week)
    previous_returned_at = previous_loan.reload.returned_at
    loan = create(:loan, book: book)

    patch return_book_url(book_id: book.id), as: :json

    assert_response :success
    response_loan = response.parsed_body
    assert_equal loan.id, response_loan.fetch("id")
    assert_equal book.id, response_loan.fetch("book_id")
    assert_equal loan.reload.returned_at.as_json, response_loan.fetch("returned_at")
    assert_in_delta time_now.to_f, loan.returned_at.to_f, 1
    assert_equal previous_returned_at, previous_loan.reload.returned_at
    assert book.reload.available?
  end

  test "does not overwrite the return date when returning a book twice" do
    loan = create(:loan)

    freeze_time do
      patch return_book_url(book_id: loan.book_id)
      assert_response :success
    end

    returned_at = loan.reload.returned_at

    travel 1.hour do
      patch return_book_url(book_id: loan.book_id)

      assert_response :conflict
      assert_equal returned_at, loan.reload.returned_at
    end
  end
end
