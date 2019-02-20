require 'test_helper'

module Draftable
  class RuleParserTest < ActiveSupport::TestCase

    test "it provides default value" do
      assert_equal ({
        up:   {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        },
        down: {
          create:   { force: ["blogs", "comments", "content", "footer", "header", "photos", "tags", "title"], merge: [] },
          update:   { force: [], merge: ["blogs", "comments", "content", "footer", "header", "photos", "tags", "title"] },
          destroy:  { force: [], merge: ["blogs", "comments", "content", "footer", "header", "photos", "tags", "title"] }
        }
      }), RuleParser.new(Post).parse

      assert_equal ({
        up:   {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] },
        },
        down: {
          create:   { force: ["content", "post", "user"], merge: [] },
          update:   { force: [], merge: ["content", "post", "user"] },
          destroy:  { force: [], merge: ["content", "post", "user"] }
        }
      }), RuleParser.new(Comment).parse
    end

    test "it parses only & except options" do
      assert_equal ({
        up:   {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        },
        down: {
          create:   { force: [], merge: ["title"] },
          update:   { force: [], merge: ["title"] },
          destroy:  { force: [], merge: ["title"] }
        }
      }), RuleParser.new(Post, [
        {
          up: :none,
          down: :merge,
          only: :title,
          except: :title # should be ignored
        }
      ]).parse

      assert_equal ({
        up:   {
          create:   { force: [], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        },
        down: {
          create:   { force: [], merge: ["content", "footer", "header", "photos", "tags"] },
          update:   { force: [], merge: ["content", "footer", "header", "photos", "tags"] },
          destroy:   { force: [], merge: ["content", "footer", "header", "photos", "tags"] }
        }
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
        up:   {
          create:   { force: ["comments", "footer", "header", "photos"], merge: ["content"] },
          update:   { force: ["comments", "footer", "header", "photos"], merge: ["content"] },
          destroy:  { force: ["comments", "footer", "header", "photos"], merge: ["content"] }
        },
        down: {
          create:   { force: ["title"], merge: ["content", "blogs", "tags"] },
          update:   { force: ["title"], merge: ["content", "blogs", "tags"] },
          destroy:  { force: ["title"], merge: ["content", "blogs", "tags"] }
        }
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
          except: ["comments", "photos", "footer", "header"]
        }, {
          up: :force,
          down: :none,
          except: [] # rest
        }
      ]).parse
    end

    test "it normalizes strategies" do
      assert_equal ({
        up:   {
          create:   { force: ["title"], merge: [] },
          update:   { force: [], merge: [] },
          destroy:  { force: [], merge: [] }
        },
        down: {
          create:   { force: [], merge: ["title"] },
          update:   { force: [], merge: ["title"] },
          destroy:  { force: [], merge: ["title"] }
        }
      }), RuleParser.new(Post, [
        {
          up: { create: :force },
          down: :merge,
          only: ["title"]
        }
      ]).parse
    end
  end
end
