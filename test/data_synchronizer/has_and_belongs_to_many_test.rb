require 'test_helper'

module Draftable
  module HasAndBelongsToMany

    class DownTest < ActiveSupport::TestCase

      force_down = {
        Post => RuleParser.new(Post, [{ up: :none, down: :force, except: [] }]).parse,
        Tag => RuleParser.new(Tag, [{ up: :none, down: :force, except: [] }]).parse
      }

      test "it copies has_and_belongs_to_many relationships" do
        author = create(:user)
        master = create(:post,
          tags: [create(:tag, name: "Travel")],
          blogs: [create(:blog)]
        )
        draft = master.to_draft(author)

        # should create drafts for draftable models

        master_tag = master.tags.first
        draft_tag = draft.tags.first

        assert_not_equal master_tag, draft_tag
        assert_equal author, draft_tag.draft_author
        assert_equal master_tag, draft_tag.draft_master
        assert_equal "Travel", draft_tag.name

        # should copy relationship with non-draftable models

        master_blog = master.blogs.first
        draft_blog = draft.blogs.first

        assert_equal master_blog, draft_blog
      end

      test "it updates attributes" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master_tag.update_attributes(name: "New name")
        synchronizer.synchronize
        draft_tag.reload

        assert_equal "New name", draft_tag.name
      end

      test "it creates records" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(tags: [create(:tag, name: "Sample name")])
        synchronizer.synchronize
        draft.reload
        master_tag = master.tags.first
        draft_tag = draft.tags.first

        assert_equal master_tag, draft_tag.draft_master
        assert_equal "Sample name", draft_tag.name
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, tags: [create(:tag)], draft_master: master, draft_author: author)

        previous_draft_tags = draft.tags
        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(tags: [create(:tag)])
        synchronizer.synchronize
        draft.reload

        assert_equal previous_draft_tags, draft.tags
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, tags: [create(:tag)], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft, force_down)
        master.update_attributes(tags: [create(:tag, name: "Sample name")])
        synchronizer.synchronize
        draft.reload
        master_tag = master.tags.first
        draft_tag = draft.tags.first

        assert_equal master_tag, draft_tag.draft_master
        assert_equal "Sample name", draft_tag.name
      end

      test "it destroys record" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master_tag.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { draft_tag.reload }
        assert_equal 0, draft.tags.count
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, tags: [create(:tag)])
        draft = create(:post, tags: [create(:tag)], draft_master: master, draft_author: author)

        draft_tag = draft.tags.first
        master_tag = master.tags.first
        synchronizer = DataSynchronizer.new(master, draft)
        master_tag.destroy
        synchronizer.synchronize

        assert_nothing_raised { draft_tag.reload }
      end

      test "after destroying self it leaves related record intact" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master_tag.destroy
        synchronizer.synchronize

        assert_nothing_raised { draft.reload }
      end
    end

    class UpTest < ActiveSupport::TestCase

      merge_up = {
        Post => RuleParser.new(Post, [{ up: :merge, down: :none, except: [] }]).parse,
        Tag => RuleParser.new(Tag, [{ up: :merge, down: :none, except: [] }]).parse
      }

      force_up = {
        Post => RuleParser.new(Post, [{ up: :force, down: :none, except: [] }]).parse,
        Tag => RuleParser.new(Tag, [{ up: :force, down: :none, except: [] }]).parse
      }

      test "it updates attributes" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft_tag.update_attributes(name: "New name")
        synchronizer.synchronize
        master_tag.reload

        assert_equal "New name", master_tag.name
      end

      test "it creates records" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(tags: [create(:tag, name: "Sample name", draft_author: author)])
        synchronizer.synchronize
        master.reload
        master_tag = master.tags.first
        draft_tag = draft.tags.first

        assert_equal draft_tag, master_tag.drafts.first
        assert_equal "Sample name", master_tag.name
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:post, tags: [create(:tag)])
        draft = create(:post, draft_master: master, draft_author: author)

        previous_master_tags = master.tags
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(tags: [create(:tag)])
        synchronizer.synchronize
        master.reload

        assert_equal previous_master_tags, master.tags
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:post, tags: [create(:tag)])
        draft = create(:post, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, force_up)
        draft.update_attributes(tags: [create(:tag, name: "Sample name", draft_author: author)])
        synchronizer.synchronize
        master.reload
        master_tag = master.tags.first
        draft_tag = draft.tags.first

        assert_equal draft_tag, master_tag.drafts.first
        assert_equal "Sample name", master_tag.name
      end

      test "it destroys record" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft_tag.destroy
        synchronizer.synchronize

        assert_raise(ActiveRecord::RecordNotFound) { master_tag.reload }
        assert_equal 0, master.tags.count
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, tags: [create(:tag)])
        draft = create(:post, tags: [create(:tag)], draft_master: master, draft_author: author)

        draft_tag = draft.tags.first
        master_tag = master.tags.first
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft_tag.destroy
        synchronizer.synchronize

        assert_nothing_raised { master_tag.reload }
      end

      test "after destroying self it leaves related record intact" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        draft_tag.destroy
        synchronizer.synchronize

        assert_nothing_raised { master.reload }
      end
    end

  end
end
