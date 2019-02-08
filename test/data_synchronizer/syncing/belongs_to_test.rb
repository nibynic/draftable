require 'test_helper'

module DataSynchronizer
  module Syncing

    class BelongsToTest < ActiveSupport::TestCase
      test "it copies belongs_to relationships" do
        author = create(:user)
        master = create(:comment,
          post: create(:post, content: "Hi everyone"),
          user: create(:user)
        )
        draft = master.to_draft(author)

        # should create drafts for draftable models

        master_post = master.post
        draft_post = draft.post

        assert_not_equal master_post, draft_post
        assert_equal author, draft_post.draft_author
        assert_equal master_post, draft_post.draft_master
        assert_equal "Hi everyone", draft_post.content

        # should copy relationship with non-draftable models

        master_user = master.user
        draft_user = draft.user

        assert_equal master_user, draft_user
      end

      test "it updates attributes" do
        author = create(:user)
        master_post = create(:post)
        master = create(:comment, post: master_post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        master.with_drafts do
          master_post.update_attributes(title: "New title")
        end
        draft.reload
        draft_post = draft.post

        assert_equal "New title", draft_post.title
      end

      test "it creates records" do
        author = create(:user)
        post = create(:post)
        master = create(:comment, post: post)
        draft = create(:comment, post: post, draft_master: master, draft_author: author)

        master.with_drafts do
          master.update_attributes(post: create(:post, title: "Sample title"))
        end
        master.reload
        draft.reload
        master_post = master.post
        draft_post = draft.post

        assert_equal master_post, draft_post.draft_master
        assert_equal "Sample title", draft_post.title
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        previous_draft_post = draft.post
        master.with_drafts do
          master.update_attributes(post: create(:post))
        end
        draft.reload
        draft_post = draft.post

        assert_equal previous_draft_post, draft_post
        assert_nil draft_post.draft_master
      end

      test "it destroys record" do
        author = create(:user)
        post = create(:post)
        master = create(:comment, post: post)
        draft = create(:comment, post: post, draft_master: master, draft_author: author)

        draft_post = draft.post
        master.with_drafts do
          master.post.destroy
        end
        draft.reload

        assert_raise(ActiveRecord::RecordNotFound) { draft_post.reload }
        assert_nil draft.post
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        draft_post = draft.post
        master.with_drafts do
          master.post.destroy
        end
        draft.reload

        assert_nothing_raised { draft_post.reload }
        assert_nil draft_post.draft_master
      end
    end

  end
end
