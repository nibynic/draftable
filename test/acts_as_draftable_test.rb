require 'test_helper'
require "spy"

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

    test "it syncs drafts" do
      author = create(:user)
      master = create(:post)
      draft = create(:post, draft_master: master, draft_author: author)

      new_spy = Spy.on(DataSynchronizer, :new).and_call_through
      synchronize_spy = Spy.on_instance_method(DataSynchronizer, :synchronize)

      master.sync_draftable do
        master.update_attributes(title: "New title")
      end

      assert_equal [master, draft], new_spy.calls.first.args
      assert_equal 1, synchronize_spy.calls.length

      new_spy.unhook
      synchronize_spy.unhook
    end

    test "it doesn't sync drafts if block returns false" do
      author = create(:user)
      master = create(:post)
      draft = create(:post, draft_master: master, draft_author: author)

      new_spy = Spy.on(DataSynchronizer, :new).and_call_through
      synchronize_spy = Spy.on_instance_method(DataSynchronizer, :synchronize)

      master.sync_draftable do
        master.update_attributes(title: "New title")
        false
      end

      assert_equal [master, draft], new_spy.calls.first.args
      assert_equal 0, synchronize_spy.calls.length

      new_spy.unhook
      synchronize_spy.unhook
    end

    test "it creates master" do
      author = create(:user)
      draft = Post.new(draft_author: author)

      new_spy = Spy.on(DataSynchronizer, :new).and_call_through
      synchronize_spy = Spy.on_instance_method(DataSynchronizer, :synchronize)

      draft.sync_draftable do
        draft.save
      end

      assert_equal [draft, nil], new_spy.calls.first.args
      assert_equal 1, synchronize_spy.calls.length

      new_spy.unhook
      synchronize_spy.unhook
    end

    test "it syncs master and its drafts" do
      author = create(:user)
      master = create(:post)
      draft_1 = create(:post, draft_master: master, draft_author: author)
      draft_2 = create(:post, draft_master: master, draft_author: author)

      new_spy = Spy.on(DataSynchronizer, :new).and_call_through
      synchronize_spy = Spy.on_instance_method(DataSynchronizer, :synchronize)

      draft_1.sync_draftable do
        draft_1.update_attributes(title: "New title")
      end

      assert_equal [draft_1, master], new_spy.calls[0].args
      assert_equal [master, draft_2], new_spy.calls[1].args
      assert_equal 2, synchronize_spy.calls.length

      new_spy.unhook
      synchronize_spy.unhook
    end

  end
end
