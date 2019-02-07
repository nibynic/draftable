require 'test_helper'

module DataSyncing
  module Down

    class SelfTest < ActiveSupport::TestCase
      test "it updates attributes" do
        author = create(:user)
        master = create(:post, title: "Sample title", content: "Sample content")
        draft = create(:post, title: "Sample title", content: "Draft content", draft_master: master, draft_author: author)

        master.with_drafts do
          master.update_attributes(title: "New title", content: "New content")
        end
        draft.reload

        assert_equal "New title", draft.title
        assert_equal "Draft content", draft.content
      end

      test "it destroys record" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Sample title", draft_master: master, draft_author: author)

        master.with_drafts do
          master.destroy
        end

        assert_raise(ActiveRecord::RecordNotFound) { draft.reload }
      end

      test "it doesn't dedtroy if draft was modified" do
        author = create(:user)
        master = create(:post, title: "Sample title")
        draft = create(:post, title: "Draft title", draft_master: master, draft_author: author)

        master.with_drafts do
          master.destroy
        end

        assert_nothing_raised { draft.reload }
      end
    end

  end
end
