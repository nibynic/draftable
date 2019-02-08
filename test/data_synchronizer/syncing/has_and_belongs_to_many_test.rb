require 'test_helper'

module DataSynchronizer
  module Syncing

    class HasAndBelongsToManyTest < ActiveSupport::TestCase

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

        master.with_drafts do
          master_tag.update_attributes(name: "New name")
        end
        draft_tag.reload

        assert_equal "New name", draft_tag.name
      end

      test "it creates records" do
        author = create(:user)
        master = create(:post)
        draft = create(:post, draft_master: master, draft_author: author)

        master.with_drafts do
          master.update_attributes(tags: [create(:tag, name: "Sample name")])
        end
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
        master.with_drafts do
          master.update_attributes(tags: [create(:tag)])
        end
        draft.reload

        assert_equal previous_draft_tags, draft.tags
      end

      test "it destroys record" do
        author = create(:user)
        master_tag = create(:tag, name: "Sample name")
        master = create(:post, tags: [master_tag])
        draft_tag = create(:tag, name: "Sample name", draft_master: master_tag, draft_author: author)
        draft = create(:post, tags: [draft_tag], draft_master: master, draft_author: author)

        master.with_drafts do
          master_tag.destroy
        end

        assert_raise(ActiveRecord::RecordNotFound) { draft_tag.reload }
        assert_equal 0, draft.tags.count
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, tags: [create(:tag)])
        draft = create(:post, tags: [create(:tag)], draft_master: master, draft_author: author)

        draft_tag = draft.tags.first
        master_tag = master.tags.first
        master.with_drafts do
          master_tag.destroy
        end

        assert_nothing_raised { draft_tag.reload }
      end
    end

  end
end
