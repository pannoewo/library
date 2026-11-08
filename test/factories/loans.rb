FactoryBot.define do
  factory :loan do
    association :book
    association :reader
    borrowed_at { 1.day.ago }
  end
end