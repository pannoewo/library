require "test_helper"

class SendLoanRemindersJobTest < ActiveSupport::TestCase
  test "sends reminders for eligible loans and skips returned or already reminded loans" do
    freeze_time do
      advance_loan = create(:loan, borrowed_at: 27.days.ago)
      due_loan = create(:loan, borrowed_at: 30.days.ago)
      returned_loan = create(:loan, borrowed_at: 27.days.ago, returned_at: Time.current)
      reminded_loan = create(:loan, borrowed_at: 30.days.ago, due_reminder_sent_at: 1.hour.ago)

      assert_difference "ActionMailer::Base.deliveries.size", 2 do
        SendLoanRemindersJob.perform_now
      end

      assert advance_loan.reload.advance_reminder_sent_at
      assert due_loan.reload.due_reminder_sent_at
      assert_nil returned_loan.reload.advance_reminder_sent_at
      assert_equal 1.hour.ago, reminded_loan.reload.due_reminder_sent_at

      emails_by_subject = ActionMailer::Base.deliveries.last(2).index_by(&:subject)
      advance_subject = "Library reminder: return #{advance_loan.book.title} by #{advance_loan.due_at.to_date}"
      due_subject = "Library reminder: return #{due_loan.book.title} by #{due_loan.due_at.to_date}"

      assert_equal [ advance_loan.reader.email ], emails_by_subject.fetch(advance_subject).to
      assert_equal [ due_loan.reader.email ], emails_by_subject.fetch(due_subject).to
    end
  end
end
