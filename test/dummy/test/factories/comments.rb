FactoryBot.define do
  factory :comment do
    content { "MyText" }
    association :post
    association :user
    association :parent, factory: :user
  end
end
