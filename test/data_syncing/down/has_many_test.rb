require 'test_helper'

module DataSyncing
  module Down

    class HasManyTest < ActiveSupport::TestCase
      test "it updates attributes" do
        author = create(:user)
        master_comment = create(:comment, content: "Sample content")
        master = create(:post, comments: [master_comment])
        draft_comment = create(:comment, content: "Sample content", draft_master: master_comment, draft_author: author)
        draft = create(:post, comments: [draft_comment], draft_master: master, draft_author: author)

        master.with_drafts do
          master_comment.update_attributes(content: "New content")
        end
        draft_comment.reload

        assert_equal draft_comment.content, "New content"
      end

      test "it creates records" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, draft_master: master, draft_author: author)

        master.with_drafts do
          master.update_attributes(comments: [create(:comment, content: "Sample content")])
        end
        draft.reload
        master_comment = master.comments.first
        draft_comment = draft.comments.first

        assert_equal master_comment, draft_comment.draft_master
        assert_equal "Sample content", draft_comment.content
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, comments: [create(:comment)], draft_master: master, draft_author: author)

        previous_draft_comments = draft.comments
        master.with_drafts do
          master.update_attributes(comments: [create(:comment)])
        end
        draft.reload

        assert_equal previous_draft_comments, draft.comments
      end

      test "it destroys record" do
        author = create(:user)
        master_comment = create(:comment)
        master = create(:post, comments: [master_comment])
        draft_comment = create(:comment, draft_master: master_comment, draft_author: author, user: master_comment.user)
        draft = create(:post, comments: [draft_comment], draft_master: master, draft_author: author)

        master.with_drafts do
          master_comment.destroy
        end

        assert_raise(ActiveRecord::RecordNotFound) { draft_comment.reload }
        assert_equal 0, draft.comments.count
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, comments: [create(:comment)])
        draft = create(:post, comments: [create(:comment)], draft_master: master, draft_author: author)

        draft_comment = draft.comments.first
        master_comment = master.comments.first
        master.with_drafts do
          master_comment.destroy
        end

        assert_nothing_raised { draft_comment.reload }
      end
    end

  end
end
