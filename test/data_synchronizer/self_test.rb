require 'test_helper'

module Draftable
  module Self

    class DownTest < ActiveSupport::TestCase
      force_down = {
        Post => RuleParser.new(Post, [{ up: :none, down: :force, except: [] }]).parse
      }

      test "it creates record" do
        author = create(:user)
        master = create(:post, title: "Sample title")

        assert_difference "Post.count", 1 do
          synchronizer = DataSynchronizer.new(master, { draft_author: author })
          synchronizer.synchronize
        end
        draft = master.drafts.first

        assert_equal "Sample title", draft.title
      end

      test "it updates attributes" do
        author = create(:user)
        master = create(:post, title: "Sample title", content: "Sample content")
        draft = create(:post, title: "Sample title", content: "Draft content", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(title: "New title", content: "New content")
        synchronizer.synchronize
        draft.reload

        assert_equal "New title", draft.title
        assert_equal "Draft content", draft.content
      end

      test "it force updates attributes" do
        author = create(:user)
        master = create(:post, title: "Sample title", content: "Sample content")
        draft = create(:post, title: "Sample title", content: "Draft content", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft, force_down)
        master.update_attributes(title: "New title", content: "New content")
        synchronizer.synchronize
        draft.reload

        assert_equal "New title", draft.title
        assert_equal "New content", draft.content
      end

      test "it destroys record" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Sample title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { draft.reload }
      end

      test "it doesn't destroy if draft was modified" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Draft title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.destroy
        synchronizer.synchronize

        assert_nothing_raised { draft.reload }
      end

      test "it force destroys if draft was modified" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Draft title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft, force_down)
        master.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { draft.reload }
      end
    end

    class UpTest < ActiveSupport::TestCase
      merge_up = {
        Post => RuleParser.new(Post, [{ up: :merge, down: :none, except: [] }]).parse
      }

      force_up = {
        Post => RuleParser.new(Post, [{ up: :force, down: :none, except: [] }]).parse
      }

      test "it creates record" do
        author = create(:user)
        draft = create(:post, title: "Sample title", draft_author: author)

        assert_difference "Post.count", 1 do
          synchronizer = DataSynchronizer.new(draft, nil, force_up)
          synchronizer.synchronize
        end
        master = draft.draft_master

        assert_equal "Sample title", master.title
      end

      test "it updates attributes" do
        author = create(:user)
        master = create(:post, title: "Sample title", content: "Sample content")
        draft = create(:post, title: "Sample title", content: "Draft content", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(title: "New title", content: "New content")
        synchronizer.synchronize
        master.reload

        assert_equal "New title", master.title
        assert_equal "Sample content", master.content
      end

      test "it force updates attributes" do
        author = create(:user)
        master = create(:post, title: "Sample title", content: "Sample content")
        draft = create(:post, title: "Sample title", content: "Draft content", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, force_up)
        draft.update_attributes(title: "New title", content: "New content")
        synchronizer.synchronize
        master.reload

        assert_equal "New title", master.title
        assert_equal "New content", master.content
      end

      test "it destroys record" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Sample title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { master.reload }
      end

      test "it doesn't destroy if draft was modified" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Draft title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.destroy
        synchronizer.synchronize

        assert_nothing_raised { master.reload }
      end

      test "it force destroys if draft was modified" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Draft title", draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, force_up)
        draft.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { master.reload }
      end
    end

  end
end
