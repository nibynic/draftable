require 'test_helper'

class Draftable::DraftBuildingTest < ActiveSupport::TestCase
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

    assert_equal master.drafts, draft_2.master_drafts
    assert_equal master.master_drafts, draft_2.master_drafts
  end

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

  test "it copies has_many relationships" do
    author = create(:user)
    master = create(:post,
      comments: [create(:comment, content: "First!!1")],
      photos: [create(:photo)]
    )
    draft = master.to_draft(author)

    # should create drafts for draftable models

    master_comment = master.comments.first
    draft_comment = draft.comments.first

    assert_not_equal master_comment, draft_comment
    assert_equal author, draft_comment.draft_author
    assert_equal master_comment, draft_comment.draft_master
    assert_equal "First!!1", draft_comment.content

    # should skip relationship with non-draftable models

    assert_equal [], draft.photos
  end

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
end
