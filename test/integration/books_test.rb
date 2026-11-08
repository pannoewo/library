require "test_helper"

class BooksTest < ActionDispatch::IntegrationTest
  test "index lists books with current availability" do
    available_book, borrowed_book, returned_book = create_list(:book, 3)

    create(:loan, book: borrowed_book)
    create(:loan, book: returned_book, returned_at: 1.week.ago)

    get books_url

    assert_response :success
    books = response.parsed_body.index_by { |book| book.fetch("id") }
    assert_equal 3, books.size
    assert_equal true, books.fetch(available_book.id).fetch("available")
    assert_equal false, books.fetch(borrowed_book.id).fetch("available")
    assert_equal true, books.fetch(returned_book.id).fetch("available")
  end

  test "show book details and its borrowing history with readers data" do
    book = create(:book)
    reader_1 = create(:reader)
    reader_2 = create(:reader)
    date_1 = 2.weeks.ago
    date_2 = 1.week.ago

    create(
      :loan,
      book: book,
      reader: reader_1,
      borrowed_at: date_1,
      returned_at: date_2
    )
    create(
      :loan,
      book: book,
      reader: reader_2,
      borrowed_at: date_2
    )

    get book_url(book)

    assert_response :success
    response_book = response.parsed_body
    history = response_book.fetch("borrowing_history")

    assert_equal book.title, response_book.fetch("title")
    assert_equal 2, history.size
    first_loan = history.first
    second_loan = history.second

    assert_equal date_1.as_json, first_loan.fetch("borrowed_at")
    assert_equal date_2.as_json, first_loan.fetch("returned_at")
    assert_equal reader_1.full_name, first_loan.dig("reader", "full_name")
    assert_equal reader_1.email, first_loan.dig("reader", "email")
    assert_equal reader_1.library_card_number, first_loan.dig("reader", "library_card_number")

    assert_equal date_2.as_json, second_loan.fetch("borrowed_at")
    assert_nil second_loan.fetch("returned_at")
    assert_equal reader_2.full_name, second_loan.dig("reader", "full_name")
    assert_equal reader_2.email, second_loan.dig("reader", "email")
    assert_equal reader_2.library_card_number, second_loan.dig("reader", "library_card_number")
  end

  test "creates a book and returns its details" do
    book_params = {
      serial_number: "123456",
      title: "The Test Book",
      author: "Test Author"
    }

    assert_difference "Book.count", 1 do
      post books_url, params: { book: book_params }, as: :json
    end

    assert_response :created
    assert_equal "123456", response.parsed_body.fetch("serial_number")
    assert_equal "The Test Book", response.parsed_body.fetch("title")
    assert_equal "Test Author", response.parsed_body.fetch("author")
    assert_equal true, response.parsed_body.fetch("available")
  end

  test "not create a book with invalid attributes" do
    invalid_book_params = {
      serial_number: "invalid",
      title: "",
      author: ""
    }

    assert_no_difference "Book.count" do
      post books_url, params: { book: invalid_book_params }, as: :json
    end

    assert_response :unprocessable_entity
    errors = response.parsed_body.fetch("errors")
    assert errors.any? { |error| error.start_with?("Serial number") }
    assert errors.any? { |error| error.start_with?("Title") }
    assert errors.any? { |error| error.start_with?("Author") }
  end

  test "returns JSON bad request when book parameters are missing" do
    post books_url, params: {}, as: :json

    assert_response :bad_request
    assert_equal "application/json", response.media_type
    assert_not_empty response.parsed_body.fetch("errors")
  end

  test "returns JSON bad request for malformed JSON" do
    post books_url,
      params: "{",
      headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }

    assert_response :bad_request
    assert_equal "application/json", response.media_type
    assert_equal({ "errors" => [ "Malformed JSON request body" ] }, response.parsed_body)
  end

  test "not create a book with duplicate serial number" do
    existing_book = create(:book, serial_number: "123456")
    duplicate_params = {
      serial_number: existing_book.serial_number,
      title: "Another Book",
      author: "Another Author"
    }

    assert_no_difference "Book.count" do
      post books_url, params: { book: duplicate_params }, as: :json
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors"), "Serial number has already been taken"
  end

  test "destroys a book" do
    book = create(:book)

    assert_difference "Book.count", -1 do
      delete book_url(book)
    end

    assert_response :no_content
  end

  test "returns not found when destroying a missing book" do
    delete book_url(id: 0)

    assert_response :not_found
  end

  test "not destroy a book with a loan" do
    book = create(:book)
    create(:loan, book: book)

    assert_no_difference "Book.count" do
      delete book_url(book)
    end

    assert_response :conflict
    assert_not_empty response.parsed_body.fetch("errors")
    assert Book.exists?(book.id)
  end
end
