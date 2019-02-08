require 'test_helper'

module Draftable
  class ActsAsDraftableTest < ActiveSupport::TestCase
    test "it finds or creates draft for given author" do
      author = create(:user)
      master = create(:post, title: "Sample post")
      existing_draft = create(:post, draft_master: master, draft_author: author)

      assert_equal existing_draft, master.to_draft(author)

      author_2 = create(:user)
      draft_2 = master.to_draft(author_2)

      assert_equal 2, master.drafts.count
      assert_equal author_2, draft_2.draft_author
      assert_equal "Sample post", draft_2.title

      assert_equal true, draft_2.draft?
      assert_equal false, draft_2.master?

      assert_equal false, master.draft?
      assert_equal true, master.master?
    end

    test "it synces drafts" do
      author = create(:user)
      master = create(:post, title: "Sample title")
      draft = create(:post, title: "Sample title", draft_master: master, draft_author: author)

      master.with_drafts do
        master.update_attributes(title: "New title")
      end
      draft.reload

      assert_equal "New title", draft.title
    end

    test "it doesn't sync drafts if block returns false" do
      author = create(:user)
      master = create(:post, title: "Sample title")
      draft = create(:post, title: "Sample title", draft_master: master, draft_author: author)

      master.with_drafts do
        master.update_attributes(title: "New title")
        false
      end
      draft.reload

      assert_equal "Sample title", draft.title
    end

  end
end
