require 'test_helper'

module DataSynchronizer
  class SnapshotsTest < ActiveSupport::TestCase

    class SnapshotsContainer
      include Draftable::Snapshots
    end

    test "it snapshots whitelisted attributes and relationships" do
      comments = create_list(:comment, 2)
      post = create(:post,
        title: "Post title",
        content: "Hello",
        comments: comments
      )

      assert_equal ({
        "title" => "Post title",
        "content" => "Hello",
        "comments" => comments
      }), SnapshotsContainer.new.snapshot(post, [:title, :content, :comments])
      assert_equal ({
        "title" => "Post title"
      }), SnapshotsContainer.new.snapshot(post, ["title"])
    end

    test "it traverses related draftable records" do
      user = create(:user)
      post = create(:post,
        comments: [
          create(:comment, user: user),
          create(:comment, user: user)
        ],
        tags: [
          create(:tag)
        ]
      )

      queue = []
      SnapshotsContainer.new.traverse(post) do |record|
        queue << record
        [:comments, :tags, :post, :user]
      end

      assert_equal [post, post.comments.first, post.comments.last, post.tags.first], queue
    end
  end
end
