require 'test_helper'

module DataSyncing
  class BaseTest < ActiveSupport::TestCase
    test "with_drafts does not perform syncing if block returns false" do
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
