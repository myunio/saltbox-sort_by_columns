# SortByColumns

A Ruby gem that provides column-based sorting capabilities for Rails models with support for associations and custom scopes.

## Features

- **Column Sorting**: Simple column sorting with direction support
- **Association Sorting**: Sort by columns in associated models using `association__column` syntax
- **Custom Scopes**: Support for custom sorting logic via `c_custom_name` pattern
- **Error Handling**: Development vs production error handling strategies
- **SQL Generation**: Proper JOIN handling with NULL value management
- **Rails Integration**: Automatic Rails integration via Railtie
- **Comprehensive Testing**: Shared examples for consistent testing across models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sort_by_columns', git: 'https://github.com/yourcompany/sort_by_columns.git'
```

And then execute:

```bash
bundle install
```

## Usage

### Model Setup

In your model, include the `SortByColumns::Model` module and specify which columns can be sorted:

```ruby
class User < ApplicationRecord
  include SortByColumns::Model

  belongs_to :organization
  has_many :posts

  column_sortable_by :name, :email, :created_at, :organization__name
end
```

### Controller Setup

In your controller, include the `SortByColumns::Controller` module:

```ruby
class UsersController < ApplicationController
  include SortByColumns::Controller

  def index
    @users = apply_scopes(User).page(params[:page])
  end
end
```

> **Note**: Make sure you call `apply_scopes` on your model scope in the controller action, or the sorting parameters won't be processed.

### API Usage

With everything set up, you can now pass the `sort` parameter in your API requests:

```
GET /users?sort=name
GET /users?sort=name:asc
GET /users?sort=name:desc
GET /users?sort=name:asc,created_at:desc
GET /users?sort=organization__name:asc
```

## Column Types

### Simple Columns

For simple model columns, just pass the column name:

```ruby
column_sortable_by :name, :email, :created_at
```

API usage:
```
GET /users?sort=name:asc
GET /users?sort=email:desc,created_at:asc
```

### Association Columns

For columns on associated models, use the `association__column` format:

```ruby
class User < ApplicationRecord
  belongs_to :organization
  
  column_sortable_by :name, :organization__name, :organization__created_at
end
```

API usage:
```
GET /users?sort=organization__name:asc
GET /users?sort=name:asc,organization__name:desc
```

#### Association Column Features

- Uses `LEFT OUTER JOIN` to ensure records with null associations are included
- Handles null values gracefully using `NULLS LAST` (for ascending sorts) or `NULLS FIRST` (for descending sorts)
- Supports custom `class_name` associations by properly using the association name as the table alias

### Custom Scope Columns

For complex sorting logic, use custom scopes with the `c_` prefix:

```ruby
class User < ApplicationRecord
  has_many :addresses
  
  column_sortable_by :name, :c_full_address

  # Required scope for custom sort
  scope :sorted_by_full_address, ->(direction) {
    joins(:addresses)
      .order("addresses.street #{direction}, addresses.city #{direction}")
  }
end
```

API usage:
```
GET /users?sort=c_full_address:desc
```

> **Important**: Custom sort columns must be used alone and cannot be combined with other columns. For example, `c_full_address,name` will not work.

## Error Handling

The gem handles invalid columns differently based on the environment:

### Development Environment
- Raises `ArgumentError` for invalid columns to help catch issues during development
- Provides detailed error messages with suggested fixes

### Production Environment
- Silently ignores invalid columns and logs warnings
- Continues processing valid columns when possible
- For custom scopes, ignores the entire sort operation if invalid

## Rails Integration

The gem includes a Railtie that automatically integrates with Rails applications:

- **Automatic Loading**: The gem automatically loads when Rails starts
- **Shared Examples**: RSpec shared examples are automatically loaded when RSpec is available
- **Configuration**: Provides `Rails.application.config.sort_by_columns` for future configuration options

The Railtie handles all the integration automatically - you don't need to do anything special.

## Testing

The gem includes shared examples to help you test your sortable models:

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  it_behaves_like "sortable by columns", {
    allowed_columns: [:name, :email, :created_at],
    disallowed_column: :password,
    associated_column: {
      name: :organization__name,
      expected_sql: "organizations.name"
    }
  }
end
```

## Dependencies

- Rails >= 7.0
- has_scope ~> 0.8

## Local Development

For local development of the gem itself:

```bash
# Set up local development
bundle config local.sort_by_columns /path/to/sort_by_columns
bundle install

# Run tests
rake spec

# Run linter
rake standard

# Build the gem
rake build
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the tests (`rake spec`)
5. Run the linter (`rake standard`)
6. Commit your changes (`git commit -am 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Examples

### Basic Model with Simple Columns

```ruby
class Post < ApplicationRecord
  include SortByColumns::Model

  column_sortable_by :title, :published_at, :view_count
end
```

### Model with Association Columns

```ruby
class Member < ApplicationRecord
  include SortByColumns::Model

  belongs_to :organization
  belongs_to :current_status, class_name: "Status", optional: true

  column_sortable_by :name, :email, :organization__name, :current_status__name
end
```

### Model with Custom Scope

```ruby
class User < ApplicationRecord
  include SortByColumns::Model

  has_many :orders

  column_sortable_by :name, :email, :c_total_orders

  scope :sorted_by_total_orders, ->(direction) {
    joins(:orders)
      .group('users.id')
      .order("COUNT(orders.id) #{direction}")
  }
end
```

### Controller Implementation

```ruby
class UsersController < ApplicationController
  include SortByColumns::Controller

  def index
    @users = apply_scopes(User.includes(:organization))
                .page(params[:page])
                .per(params[:per_page] || 25)
  end
end
```

### API Examples

```bash
# Sort by name ascending (default)
curl "http://localhost:3000/users?sort=name"

# Sort by name descending
curl "http://localhost:3000/users?sort=name:desc"

# Multiple column sort
curl "http://localhost:3000/users?sort=name:asc,created_at:desc"

# Association column sort
curl "http://localhost:3000/users?sort=organization__name:asc"

# Custom scope sort
curl "http://localhost:3000/users?sort=c_total_orders:desc"
``` 
