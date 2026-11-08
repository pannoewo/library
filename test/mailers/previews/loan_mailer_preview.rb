class LoanMailerPreview < ActionMailer::Preview
  def three_days_before_due_date
    LoanMailer.return_reminder(sample_loan(Date.current + 3))
  end

  def on_due_date
    LoanMailer.return_reminder(sample_loan(Date.current))
  end

  private

  def sample_loan(due_date)
    due_at = due_date.in_time_zone.noon
    book = Book.new(serial_number: "123456", title: "The Hobbit", author: "J. R. R. Tolkien")
    reader = Reader.new(library_card_number: "234567", full_name: "Anna Nowak", email: "anna@example.com")

    Loan.new(book: book, reader: reader, borrowed_at: due_at - 30.days, due_at: due_at)
  end
end
