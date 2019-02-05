FactoryBot.define do
  factory :comment do
    content { "MyText" }
    association :post
    association :user
  end
end
