require 'test_helper'

class Draftable::OptionsNormalizationTest < ActiveSupport::TestCase

  test "it detects all attribute and relationship methods" do
    class Post < ApplicationRecord
      acts_as_draftable
      has_many :comments
    end

    assert_equal ["content", "title", "comments"].sort, Post.draftable_methods.sort

    self.class.send(:remove_const, "Post")
  end

  test "it detects supports only option" do
    class Post < ApplicationRecord
      acts_as_draftable only: :title
      has_many :comments
    end

    assert_equal ["title"].sort, Post.draftable_methods.sort

    self.class.send(:remove_const, "Post")
  end

  test "it detects supports except option" do
    class Post < ApplicationRecord
      acts_as_draftable except: [:title, :content]
      has_many :comments
    end

    assert_equal ["comments"].sort, Post.draftable_methods.sort

    self.class.send(:remove_const, "Post")
  end

end
