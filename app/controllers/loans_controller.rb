class LoansController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :render_loan_errors
  rescue_from ActiveRecord::RecordNotUnique, with: :render_borrowing_conflict

  before_action :find_book, only: :return

  def create
    loan = Loan.create!(loan_params.merge(borrowed_at: Time.current))

    render json: loan_json(loan), status: :created
  end

  def return
    loan = @book.loans.find_by(returned_at: nil)
    return render json: { errors: [ "Book is not currently borrowed" ] }, status: :conflict if loan.nil?

    loan.update!(returned_at: Time.current)
    render json: loan_json(loan), status: :ok
  end

  private

  def render_loan_errors(error)
    errors = error.record.errors
    status = errors.of_kind?(:book_id, :taken) ? :conflict : :unprocessable_entity
    render json: { errors: errors.full_messages }, status: status
  end

  def render_borrowing_conflict
    render json: { errors: [ "Book is already borrowed" ] }, status: :conflict
  end

  def find_book
    @book = Book.find(params[:book_id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: [ "Book not found" ] }, status: :not_found
  end

  def loan_params
    params.require(:loan).permit(:book_id, :reader_id)
  end

  def loan_json(loan)
    {
      id: loan.id,
      book_id: loan.book_id,
      reader_id: loan.reader_id,
      borrowed_at: loan.borrowed_at,
      due_at: loan.due_at,
      returned_at: loan.returned_at
    }
  end
end
