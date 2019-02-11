# Draftable
Yet another drafts gem for Rails. What makes Draftable different?

- it uses source model for drafts: your blog post draft will be still BlogPost,
with all its validation, controller and serialization logic,
- it allows multiple drafts per master (one per author),
- it automatically propagates changes from master to all its drafts,
- it can also propagate changes from draft to master.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'draftable'
```

And then execute:
```bash
$ bundle
```

## Basic concepts
Draftable builds on a concept of __master__ (original / published / verified data)
and its __drafts__ (derivate / personal / unverified data).

Each draft keeps a full copy of master data (including related records). Drafts
and master are kept in sync, propagating changes from master to drafts (__down__)
and from draft to master (__up__).

Potential synchronization conflicts can be resolved in two ways: by leaving
destination data untouched (__merge__) or by overwriting it with source data
(__force__).

You can control data flow precisely via [sync rules](#sync-rules).
By default Draftable will just merge data down.

Draftable assumes that there can be only one draft per master-author pair.

## Setup
Draftable needs to add some columns to your tables (`draft_author_id`,
`draft_author_type`, `draft_master_id`). It can generate necessary migrations
for you, just run

```bash
rails g draftable:init ModelName
```

This will also add `acts_as_draftable` in your model.

## Usage
To make your model draftable just add in its class (this should be already done
by generator described above):

```ruby
class MyModel < ApplicationRecord
  acts_as_draftable
end
```

Then you can create a draft:

```ruby
model = MyModel.find(1)
author = current_user # any Active Record model

draft = model.to_draft(author)

draft.draft? # true
model.master? # true
```

To keep draft and master in sync, always wrap your updates in a `sync_draftable` block:

```ruby
model.sync_draftable do
  model.update_attributes(name: "New name")
end

draft.name # "New name"
```

### Sync rules
```ruby
def MyModel < ApplicationRecord
  acts_as_draftable [
    {
      up: :none,
      down: :merge,
      only: ["first_name", "last_name", "tags"]
    }, {
      up: :force,
      down: :force,
      except: []
    }
  ]
end
```

`acts_as_draftable` method accepts an array of sync rules. These rules are parsed
from top to bottom. Consecutive rules apply to only attributes that are left
from preceding rules. Each rule can be defined by 3 of these 4 properties:

- `up` - conflict resolution strategy when syncing up, can be `:force`, `:merge`
or `:none` (default),
- `down` - conflict resolution strategy when syncing down, can be `:force`, `:merge`
or `:none` (default),
- `only` - whitelist of attribute and relationship names that should be synced.
If defined, `except` param will be ignored. Default: `nil`,
- `except` - blacklist of attribute and relationship names - they won't be synced.
The rule will be applied for all names left. Default: `[]`.

By default Draftable uses only this one rule, which only merges data down:

```ruby
{
  up: :none,
  down: :merge,
  except: []
}
```

When creating new records (both drafts and masters) Draftable will use a separate
strategy that copies all data from source to destination (force method on all
attributes). Relationship copying depends on association type and whether the source
record is draftable or not. This mechanism ensures that non-draftable records
are won't be hijacked by destination record.

| Association             | Draftable                | Non-draftable |
| ----------------------- | ------------------------ | ------------- |
| belongs_to              | creates a draft / master | uses source   |
| has_many                | creates a draft / master | leaves empty  |
| has_and_belongs_to_many | creates a draft / master | uses source   |



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
