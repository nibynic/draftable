require 'test_helper'

module Draftable
  class RuleParserTest < ActiveSupport::TestCase

    test "it provides default value" do
      assert_equal ({
        up:   { force: [], merge: [] },
        down: { force: [], merge: ["blogs", "comments", "content", "photos", "tags", "title"] },
        full: { force: ["blogs", "comments", "content", "photos", "tags", "title"], merge: [] }
      }), RuleParser.new(Post).parse

      assert_equal ({
        up:   { force: [], merge: [] },
        down: { force: [], merge: ["content", "post", "user"] },
        full: { force: ["content", "post", "user"], merge: [] }
      }), RuleParser.new(Comment).parse
    end

    test "it parses only & except options" do
      assert_equal ({
        up:   { force: [], merge: [] },
        down: { force: [], merge: ["title"] },
        full: { force: ["blogs", "comments", "content", "photos", "tags", "title"], merge: [] }
      }), RuleParser.new(Post, [
        {
          up: :none,
          down: :merge,
          only: :title,
          except: :title # should be ignored
        }
      ]).parse

      assert_equal ({
        up:   { force: [], merge: [] },
        down: { force: [], merge: ["content", "photos", "tags"] },
        full: { force: ["blogs", "comments", "content", "photos", "tags", "title"], merge: [] }
      }), RuleParser.new(Post, [
        {
          up: :none,
          down: :merge,
          except: [:title, :blogs, "comments"]
        }
      ]).parse
    end

    test "it resolves rules top to bottom" do
      assert_equal ({
        up:   { force: ["comments", "photos"], merge: ["content"] },
        down: { force: ["title"], merge: ["content", "blogs", "tags"] },
        full: { force: ["blogs", "comments", "content", "photos", "tags", "title"], merge: [] }
      }), RuleParser.new(Post, [
        {
          up: :none,
          down: :force,
          only: ["title"]
        }, {
          up: :merge,
          down: :merge,
          only: ["content", "title"] # title should be ignored
        }, {
          up: :none,
          down: :merge,
          except: ["comments", "photos"]
        }, {
          up: :force,
          down: :none,
          except: [] # rest
        }
      ]).parse
    end
  end
end
