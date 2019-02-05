# Draftable
Yet another drafts gem for Rails. What makes Draftable different?

- it uses source model for drafts: so your blog post draft will be still BlogPost,
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
Draftable builds on a concept of _master_ (original / published / verified data)
and its _drafts_ (derivate / personal / unverified data).

Each draft keeps a full copy of master data (including related records).

By default Draftable will propagate each change in master data into its drafts
(down), as long as it doesn't collide with local draft changes.

If needed, changes in drafts can also be copied into master (up) and then into
all its drafts (down). This can be useful when implementing verification
mechanism that applies only to selected model attributes.

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

### Creating drafts

```ruby
model.to_draft(author)
```

This will copy all data and related records (if possible) into a new draft and then
save it. Related records copying depends on association type and whether the related
record is draftable or not:

| Association             | Draftable       | Non-draftable |
| ----------------------- | --------------- | ------------- |
| belongs_to              | creates a draft | uses master   |
| has_many                | creates a draft | leaves empty  |
| has_and_belongs_to_many | creates a draft | uses master   |



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
