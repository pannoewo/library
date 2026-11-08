class SendLoanRemindersJob < ApplicationJob
  def perform
    today = Date.current

    { 3 => :advance_reminder_sent_at, 0 => :due_reminder_sent_at }.each do |days_before, sent_at_column|
      due_day = today + days_before
      loans = Loan.where(returned_at: nil, due_at: due_day.all_day)
        .where(sent_at_column => nil)
        .includes(:book, :reader)

      loans.find_each do |loan|
        LoanMailer.return_reminder(loan).deliver_now
        loan.update!(sent_at_column => Time.current)
      end
    end
  end
end
