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
      up: { create: :force, update: :force },
      down: :force,
      except: []
    }
  ]
end
```

`acts_as_draftable` method accepts an array of sync rules. These rules are parsed
from top to bottom. Consecutive rules apply to only attributes that are left
from preceding rules. Each rule is defined by three of these properties:

- `up` - conflict resolution strategy when syncing up, default `:none`,
- `down` - conflict resolution strategy when syncing down, default `:none`,
- `only` - whitelist of attribute and relationship names that should be synced.
If defined, `except` param will be ignored. Default: `nil`,
- `except` - blacklist of attribute and relationship names - they won't be synced.
The rule will be applied for all names left. Default: `[]`.

Conflict resolution strategies are defined by a hash with `create`, `update` and
`destroy` keys (each defining a strategy for creating / updating / destroying record).
Available strategies are:

- `:force` - this will overwrite all data with source data,
- `:merge` - update only these attributes that were the same in source and destination record,
- `:none` - do nothing (default).

If you pass a symbol instead of a hash it will be automatically expanded by applying
same value in all three cases. E.g. `:force` will become
`{ create: :force, update: :force, destroy: :force }`.


By default Draftable uses only this one rule, which only merges data down:

```ruby
{
  up: :none,
  down: { create: :force, update: :merge, destroy: :merge },
  except: []
}
```
#### Relationship copying

Draftable tries to copy data in all listed relationships. In some cases this
cannot be done - e.g. simple copying has_many relationship from master to draft
would hijack master records (related records would be attached to draft instead).
To prevent this effect, relationship copying depends on association type and
whether the source record is draftable or not.

| Association             | Draftable                | Non-draftable |
| ----------------------- | ------------------------ | ------------- |
| belongs_to              | creates a draft / master | uses source   |
| has_many                | creates a draft / master | leaves empty  |
| has_and_belongs_to_many | creates a draft / master | uses source   |

#### Creating records

Draftable will use `create` rules if destination record is not persisted.
In this case `force` strategy will copy all listed attributes, while `merge`
strategy will compare them with initial values. If no attributes match `create`
rule, record will not be created.

#### Destroying records

Draftable will use `destroy` rules if source record is destroyed. In this case
`force` strategy will always destroy destination record, while `merge` will compare
listed attributes and destroy only if none of them was changed. If no attributes
match `destroy` rule, record will not be destroyed.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
