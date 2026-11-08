class BooksController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :render_book_errors
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordNotDestroyed, with: :render_destroy_errors

  before_action :find_book, only: :destroy
  before_action :find_book_with_history, only: :show

  def index
    books = Book.includes(:loans).order(:id)
    render json: books.map { |book| book_json(book) }
  end

  def show
    render json: book_json(@book).merge(
      borrowing_history: borrowing_history_json(@book)
    )
  end

  def create
    book = Book.create!(book_params)

    render json: book_json(book), status: :created
  end

  def destroy
    @book.destroy!
    head :no_content
  end

  private

  def render_book_errors(error)
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_destroy_errors(error)
    render json: { errors: error.record.errors.full_messages }, status: :conflict
  end

  def render_not_found(error)
    render json: { errors: [ error.message ] }, status: :not_found
  end

  def find_book
    @book = Book.find(params[:id])
  end

  def find_book_with_history
    @book = Book.includes(loans: :reader).find(params[:id])
  end

  def book_params
    params.require(:book).permit(:serial_number, :title, :author)
  end

  def book_json(book)
    {
      id: book.id,
      serial_number: book.serial_number,
      title: book.title,
      author: book.author,
      available: book.available?
    }
  end

  def borrowing_history_json(book)
    book.loans.sort_by { |loan| [ loan.borrowed_at, loan.id ] }.map do |loan|
      {
        borrowed_at: loan.borrowed_at,
        returned_at: loan.returned_at,
        reader: {
          id: loan.reader.id,
          library_card_number: loan.reader.library_card_number,
          full_name: loan.reader.full_name,
          email: loan.reader.email
        }
      }
    end
  end
end
