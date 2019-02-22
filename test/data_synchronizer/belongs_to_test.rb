require 'test_helper'

module Draftable

  module BelongsTo

    class DownTest < ActiveSupport::TestCase

      force_down = {
        Post => RuleParser.new(Post, [{ up: :none, down: :force, except: [] }]).parse,
        Comment => RuleParser.new(Comment, [{ up: :none, down: :force, except: [] }]).parse
      }

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

        synchronizer = DataSynchronizer.new(master, draft)
        master_post.update_attributes(title: "New title")
        synchronizer.synchronize
        draft.reload
        draft_post = draft.post

        assert_equal "New title", draft_post.title
      end

      test "it creates records" do
        author = create(:user)
        master_post = create(:post)
        master = create(:comment, post: master_post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(post: create(:post, title: "Sample title"))
        synchronizer.synchronize
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
        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(post: create(:post))
        synchronizer.synchronize
        draft.reload
        draft_post = draft.post

        assert_equal previous_draft_post, draft_post
        assert_nil draft_post.draft_master
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft, force_down)
        master.update_attributes(post: create(:post, title: "Sample title"))
        synchronizer.synchronize
        master.reload
        draft.reload
        master_post = master.post
        draft_post = draft.post

        assert_equal master_post, draft_post.draft_master
        assert_equal "Sample title", draft_post.title
      end

      test "it destroys record" do
        author = create(:user)
        master_post = create(:post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        master = create(:comment, post: master_post)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master_post.destroy
        synchronizer.synchronize
        draft.reload

        assert_raise(ActiveRecord::RecordNotFound) { draft_post.reload }
        assert_nil draft.post
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        draft_post = draft.post
        synchronizer = DataSynchronizer.new(master, draft)
        master.post.destroy
        synchronizer.synchronize
        draft.reload

        assert_nothing_raised { draft_post.reload }
        assert_nil draft_post.draft_master
      end

      test "after destroying self it leaves related record intact" do
        author = create(:user)
        master_post = create(:post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        master = create(:comment, post: master_post)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.destroy
        synchronizer.synchronize

        assert_nothing_raised { draft_post.reload }
      end
    end

    class UpTest < ActiveSupport::TestCase

      merge_up = {
        Post => RuleParser.new(Post, [{ up: :merge, down: :none, except: [] }]).parse,
        Comment => RuleParser.new(Comment, [{ up: :merge, down: :none, except: [] }]).parse
      }

      force_up = {
        Post => RuleParser.new(Post, [{ up: :force, down: :none, except: [] }]).parse,
        Comment => RuleParser.new(Comment, [{ up: :force, down: :none, except: [] }]).parse
      }

      test "it updates attributes" do
        author = create(:user)
        master_post = create(:post)
        master = create(:comment, post: master_post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft_post.update_attributes(title: "New title")
        synchronizer.synchronize
        master.reload
        master_post = master.post

        assert_equal "New title", master_post.title
      end

      test "it creates records" do
        author = create(:user)
        master_post = create(:post)
        master = create(:comment, post: master_post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(post: create(:post, title: "Sample title", draft_author: author))
        synchronizer.synchronize
        draft.reload
        master.reload
        draft_post = draft.post
        master_post = master.post

        assert_equal draft_post, master_post.drafts.first
        assert_equal "Sample title", master_post.title
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        previous_master_post = master.post
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(post: create(:post))
        synchronizer.synchronize
        master.reload
        master_post = master.post

        assert_equal previous_master_post, master_post
        assert_nil master_post.drafts.first
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        previous_master_post = master.post
        synchronizer = DataSynchronizer.new(draft, master, force_up)
        draft.update_attributes(post: create(:post, title: "Sample title", draft_author: author))
        synchronizer.synchronize
        draft.reload
        master.reload
        draft_post = draft.post
        master_post = master.post

        assert_equal draft_post, master_post.drafts.first
        assert_equal "Sample title", master_post.title
      end

      test "it destroys record" do
        author = create(:user)
        post = create(:post)
        master_post = create(:post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        master = create(:comment, post: master_post)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        master_post = master.post
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.post.destroy
        synchronizer.synchronize
        master.reload

        assert_raise(ActiveRecord::RecordNotFound) { master_post.reload }
        assert_nil master.post
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:comment, post: create(:post))
        draft = create(:comment, post: create(:post), draft_master: master, draft_author: author)

        master_post = master.post
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.post.destroy
        synchronizer.synchronize
        master.reload

        assert_nothing_raised { master_post.reload }
        assert_nil master_post.drafts.first
      end

      test "after destroying self it leaves related record intact" do
        author = create(:user)
        master_post = create(:post)
        draft_post = create(:post, draft_master: master_post, draft_author: author)
        master = create(:comment, post: master_post)
        draft = create(:comment, post: draft_post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        draft.destroy
        synchronizer.synchronize

        assert_nothing_raised { master_post.reload }
      end
    end

  end
end
