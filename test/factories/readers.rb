FactoryBot.define do
  factory :reader do
    sequence(:library_card_number) { |number| format("%06d", number) }
    full_name { "Test Reader" }
    sequence(:email) { |number| "reader#{number}@example.com" }
  end
end