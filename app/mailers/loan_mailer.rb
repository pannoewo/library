class LoanMailer < ApplicationMailer
  def return_reminder(loan)
    @loan = loan

    mail(
      to: loan.reader.email,
      subject: "Library reminder: return #{loan.book.title} by #{loan.due_at.to_date}"
    )
  end
end
