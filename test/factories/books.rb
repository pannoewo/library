FactoryBot.define do
  factory :book do
    sequence(:serial_number) { |number| format("%06d", number) }
    sequence(:title) { |number| "Book #{number}" }
    author { "Test Author" }
  end
end