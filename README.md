# Hawk

[![Build Status](https://github.com/ifad/hawk/actions/workflows/ruby.yml/badge.svg)](https://github.com/ifad/hawk/actions/workflows/ruby.yml)
[![RuboCop](https://github.com/ifad/hawk/actions/workflows/rubocop.yml/badge.svg)](https://github.com/ifad/hawk/actions/workflows/rubocop.yml)

Hawk is an API Client framework. It is used as a base to then build your API
clients. It consumes JSON and produces Ruby objects without any Hash magic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hawk', github: 'ifad/hawk'
```

And then execute:

```sh
$ bundle install
```

## Usage

### Defining a Model

Create a model class that inherits from `Hawk::Model::Base`:

```ruby
class Post < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  schema do
    integer :id
    string :title, :body
    datetime :created_at
    boolean :published
  end
end
```

### Finding Records

```ruby
# Find by ID
post = Post.find(1)
post.title # => "Hello World"

# Find multiple records
posts = Post.find([1, 2, 3])

# Get all records
posts = Post.all

# Get first record
post = Post.first
post = Post.first! # Raises Hawk::Error::NotFound if not found
```

### Querying

```ruby
# Filter with where
posts = Post.where(published: true)

# Chain queries
posts = Post.where(published: true).order(:created_at).limit(10)

# Use offsets
posts = Post.offset(20).limit(10)

# Custom endpoints
posts = Post.from('featured')
```

### Defining Scopes

```ruby
class Post < Hawk::Model::Base
  # ... schema ...

  scope :published, -> { where(published: true) }
  scope :recent, -> { order(:created_at).limit(10) }
  scope :by_author, ->(name) { where(author: name) }
end

# Use scopes
Post.published.all
Post.recent.by_author('John').limit(5)
```

### Associations

```ruby
class Farm < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  schema do
    integer :id
    string :name
  end

  has_many :animals
end

class Animal < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  schema do
    integer :id, :farm_id
    string :name
  end

  belongs_to :farm
  has_one :favourite_food, class_name: 'Food'
end

class Food < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  schema do
    integer :id
    string :name
  end
end

# Usage
farm = Farm.find(1)
farm.animals.all # => Collection of Animal records

animal = Animal.find(1)
animal.farm # => Farm record
animal.favourite_food # => Food record
```

### Polymorphic Associations

```ruby
class Image < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  schema do
    integer :id, :imageable_id
    string :url, :imageable_type
  end

  belongs_to :imageable, polymorphic: true
end

# Usage
image = Image.find(1)
image.imageable # => Returns the associated record (Animal, Post, etc.)
```

### Caching

Hawk supports Memcached-based caching for GET requests:

```ruby
class Post < Hawk::Model::Base
  url 'https://api.example.com/'
  client_name 'MyApp/1.0'

  http_options(
    cache: {
      server: 'localhost:11211',
      namespace: 'myapp',
      expires_in: 300
    }
  )

  # ... schema ...
end
```

### Error Handling

```ruby
begin
  post = Post.find(999)
rescue Hawk::Error::NotFound => e
  puts "Post not found: #{e.message}"
rescue Hawk::Error::Timeout => e
  puts "Request timed out: #{e.message}"
rescue Hawk::Error::HTTP => e
  puts "HTTP error #{e.code}: #{e.message}"
end
```

### Persisting Records

```ruby
post = Post.new(title: "Hello", body: "World")
post.save! # Sends PUT request to API
post.persisted? # => true

# Track changes
post.title = "Updated"
post.changed? # => true
post.changes # => { "title" => ["Hello", "Updated"] }
```

### Instrumentation

Hawk logs HTTP requests to stderr by default. You can suppress this output:

```ruby
Hawk::HTTP::Instrumentation.suppress_verbose_output true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To build a local gem artifact, update the version number in `lib/hawk/version.rb` and then run `bundle exec rake build`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hawk/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Denominazione d'Origine Controllata

This software is Made in Italy :it: :smile:.
