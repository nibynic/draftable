require 'test_helper'

module Draftable

  module HasOne

    class DownTest < ActiveSupport::TestCase

      force_down = {
        Post => RuleParser.new(Post, [{ up: :none, down: :force, except: [] }]).parse,
        Header => RuleParser.new(Header, [{ up: :none, down: :force, except: [] }]).parse
      }

      test "it copies has_one relationships" do
        author = create(:user)
        master = create(:post,
          header: create(:header, content: "Hi everyone"),
          footer: create(:footer)
        )
        draft = master.to_draft(author)

        # should create drafts for draftable models

        master_header = master.header
        draft_header = draft.header

        assert_not_equal master_header, draft_header
        assert_equal author, draft_header.draft_author
        assert_equal master_header, draft_header.draft_master
        assert_equal "Hi everyone", draft_header.content

        # should skip relationship with non-draftable models

        assert_nil draft.footer
      end

      test "it updates attributes" do
        author = create(:user)
        master_header = create(:header)
        master = create(:post, header: master_header)
        draft_header = create(:header, draft_master: master_header, draft_author: author)
        draft = create(:post, header: draft_header, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master_header.update_attributes(content: "New content")
        synchronizer.synchronize
        draft.reload
        draft_header = draft.header

        assert_equal "New content", draft_header.content
      end

      test "it creates records" do
        author = create(:user)
        master_header = create(:header)
        master = create(:post, header: master_header)
        draft_header = create(:header, draft_master: master_header, draft_author: author)
        draft = create(:post, header: draft_header, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(header: create(:header, content: "Sample content"))
        synchronizer.synchronize
        master.reload
        draft.reload
        master_header = master.header
        draft_header = draft.header

        assert_equal master_header, draft_header.draft_master
        assert_equal "Sample content", draft_header.content
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        previous_draft_header = draft.header
        synchronizer = DataSynchronizer.new(master, draft)
        master.update_attributes(header: create(:header))
        synchronizer.synchronize
        draft.reload
        draft_header = draft.header

        assert_equal previous_draft_header, draft_header
        assert_nil draft_header.draft_master
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(master, draft, force_down)
        master.update_attributes(header: create(:header, content: "Sample content"))
        synchronizer.synchronize
        master.reload
        draft.reload
        master_header = master.header
        draft_header = draft.header

        assert_equal master_header, draft_header.draft_master
        assert_equal "Sample content", draft_header.content
      end

      test "it destroys record" do
        author = create(:user)
        header = create(:header)
        master = create(:post, header: header)
        draft = create(:post, header: header, draft_master: master, draft_author: author)

        draft_header = draft.header
        synchronizer = DataSynchronizer.new(master, draft)
        master.header.destroy
        synchronizer.synchronize
        draft.reload

        assert_raise(ActiveRecord::RecordNotFound) { draft_header.reload }
        assert_nil draft.header
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        draft_header = draft.header
        synchronizer = DataSynchronizer.new(master, draft)
        master.header.destroy
        synchronizer.synchronize
        draft.reload

        assert_nothing_raised { draft_header.reload }
        assert_nil draft_header.draft_master
      end
    end

    class UpTest < ActiveSupport::TestCase

      merge_up = {
        Post => RuleParser.new(Post, [{ up: :merge, down: :none, except: [] }]).parse,
        Header => RuleParser.new(Header, [{ up: :merge, down: :none, except: [] }]).parse
      }

      force_up = {
        Post => RuleParser.new(Post, [{ up: :force, down: :none, except: [] }]).parse,
        Header => RuleParser.new(Header, [{ up: :force, down: :none, except: [] }]).parse
      }

      test "it updates attributes" do
        author = create(:user)
        master_header = create(:header)
        master = create(:post, header: master_header)
        draft_header = create(:header, draft_master: master_header, draft_author: author)
        draft = create(:post, header: draft_header, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft_header.update_attributes(content: "New content")
        synchronizer.synchronize
        master.reload
        master_header = master.header

        assert_equal "New content", master_header.content
      end

      test "it creates records" do
        author = create(:user)
        master_header = create(:header)
        master = create(:post, header: master_header)
        draft_header = create(:header, draft_master: master_header, draft_author: author)
        draft = create(:post, header: draft_header, draft_master: master, draft_author: author)

        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(header: create(:header, content: "Sample content", draft_author: author))
        synchronizer.synchronize
        draft.reload
        master.reload
        draft_header = draft.header
        master_header = master.header

        assert_equal draft_header, master_header.drafts.first
        assert_equal "Sample content", master_header.content
      end

      test "it doesn't create if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        previous_master_header = master.header
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.update_attributes(header: create(:header))
        synchronizer.synchronize
        master.reload
        master_header = master.header

        assert_equal previous_master_header, master_header
        assert_nil master_header.drafts.first
      end

      test "it force creates if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        previous_master_header = master.header
        synchronizer = DataSynchronizer.new(draft, master, force_up)
        draft.update_attributes(header: create(:header, content: "Sample content", draft_author: author))
        synchronizer.synchronize
        draft.reload
        master.reload
        draft_header = draft.header
        master_header = master.header

        assert_equal draft_header, master_header.drafts.first
        assert_equal "Sample content", master_header.content
      end

      test "it destroys record" do
        author = create(:user)
        header = create(:header)
        master = create(:post, header: header)
        draft = create(:post, header: header, draft_master: master, draft_author: author)

        master_header = master.header
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.header.destroy
        synchronizer.synchronize
        master.reload

        assert_raise(ActiveRecord::RecordNotFound) { master_header.reload }
        assert_nil master.header
      end

      test "it doesn't destroy if relationship was modified" do
        author = create(:user)
        master = create(:post, header: create(:header))
        draft = create(:post, header: create(:header), draft_master: master, draft_author: author)

        master_header = master.header
        synchronizer = DataSynchronizer.new(draft, master, merge_up)
        draft.header.destroy
        synchronizer.synchronize
        master.reload

        assert_nothing_raised { master_header.reload }
        assert_nil master_header.drafts.first
      end
    end

  end
end
