# Simple Record
## Introduction
This repository is created for learning purpose. I try to re-implement these basic features of Rails ActiveRecord by myself:
- Some basic query methods.
- Basic associations.

## Basic query methods
### .find
Find a record by primary key. It will return a simple record object.
```ruby
user = User.find 1
```
### .where
Find a collection of records by condition.
```ruby
users = User.where(name: ['Huy', 'Harry', 'Phung'])
```
You can chain `.where` method as same as Rails ActiveRecord.
```ruby
users = User.where(name: ['Huy', 'Harry', 'Phung']).where(role: 'Admin')
```
The `.where` chain is lazy load. It only hit the Database when use use `.evaluate`
```ruby
users = User.where(name: ['Huy', 'Harry', 'Phung']).evaluate
```
### includes
Includes work as same as Rails ActiveRecord includes to reload relationships. `.includes` is lazy load as same as `.where`.
```ruby
users = User.where(name: ['Huy', 'Harry', 'Phung']).includes(:posts).where(role: 'Admin').evaluate
```

## Basic association method
### has_many
```ruby
# Basic case
has_many :post

# Or more options
has_many :post, foreign_key: :owner_id, class_name: BlogPost
```
