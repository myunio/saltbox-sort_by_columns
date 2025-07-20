# Testing Guide for Saltbox::SortByColumns

This document provides comprehensive testing information for the Saltbox::SortByColumns gem, including test patterns, conventions, and examples for consuming applications.

## Test Coverage Overview

The gem has **100% test coverage** with comprehensive testing across all scenarios:

- **326 examples, 0 failures** (100% pass rate)
- **Line Coverage**: 100.0% (109/109 lines)
- **Branch Coverage**: 91.67% (44/48 branches)
- **7 testing phases** covering everything from basic functionality to real-world integration

## Test Suite Structure

### Directory Organization

```
spec/
├── integration/                    # High-level integration tests
│   ├── controller_integration_spec.rb    # Real Rails controller testing
│   └── sort_by_columns_integration_spec.rb  # End-to-end gem functionality
├── rails_app/                     # Combustion test Rails app
│   ├── config/
│   └── db/
├── saltbox/
│   └── sort_by_columns/           # Core unit tests
│       ├── controller_spec.rb           # Controller module tests
│       ├── model_basic_spec.rb          # Basic model functionality
│       ├── model_edge_cases_spec.rb     # Input validation & edge cases
│       ├── model_error_handling_spec.rb # Error scenarios & environments
│       ├── model_sql_generation_spec.rb # SQL output verification
│       ├── model_advanced_features_spec.rb # Custom scopes & complex features
│       ├── railtie_spec.rb              # Rails integration
│       └── sort_by_columns_spec.rb      # Smoke tests
└── support/
    ├── shared_examples/           # Reusable test patterns
    └── shared_examples.rb         # Main shared examples file
```

### Phase-Based Testing Approach

The test suite is organized into 7 comprehensive phases:

1. **Phase 1: Foundation** (54 tests) - Core functionality and basic integration
2. **Phase 2: Edge Cases & Input Validation** (74 tests) - Malformed input and edge cases
3. **Phase 3: Error Handling & Environment Behavior** (63 tests) - Multi-environment testing
4. **Phase 4: SQL Generation & Association Testing** (29 tests) - SQL output verification
5. **Phase 5: Advanced Features & Custom Scopes** (57 tests) - Complex functionality
6. **Phase 6: Controller Integration & Real-World Testing** (39 tests) - Full Rails integration
7. **Phase 7: Performance, Security & Quality** - Code coverage and validation

## Running Tests

### Full Test Suite

```bash
# Run all tests with coverage
bundle exec rspec

# Run all tests with detailed output
bundle exec rspec --format documentation

# Run tests with progress output
bundle exec rspec --format progress
```

### Running Specific Test Phases

```bash
# Phase 1: Foundation tests
bundle exec rspec spec/saltbox/sort_by_columns/model_basic_spec.rb
bundle exec rspec spec/saltbox/sort_by_columns/controller_spec.rb
bundle exec rspec spec/saltbox/sort_by_columns/railtie_spec.rb

# Phase 2: Edge cases and input validation
bundle exec rspec spec/saltbox/sort_by_columns/model_edge_cases_spec.rb

# Phase 3: Error handling and environment behavior
bundle exec rspec spec/saltbox/sort_by_columns/model_error_handling_spec.rb

# Phase 4: SQL generation and association testing
bundle exec rspec spec/saltbox/sort_by_columns/model_sql_generation_spec.rb

# Phase 5: Advanced features and custom scopes
bundle exec rspec spec/saltbox/sort_by_columns/model_advanced_features_spec.rb

# Phase 6: Controller integration and real-world testing
bundle exec rspec spec/integration/controller_integration_spec.rb
bundle exec rspec spec/integration/sort_by_columns_integration_spec.rb

# Smoke tests
bundle exec rspec spec/saltbox/sort_by_columns/sort_by_columns_spec.rb
```

### Running Specific Test Categories

```bash
# Unit tests only
bundle exec rspec spec/saltbox/sort_by_columns/

# Integration tests only
bundle exec rspec spec/integration/

# Controller-specific tests
bundle exec rspec spec/saltbox/sort_by_columns/controller_spec.rb spec/integration/controller_integration_spec.rb

# Model-specific tests
bundle exec rspec spec/saltbox/sort_by_columns/model_*.rb

# Error handling tests
bundle exec rspec spec/saltbox/sort_by_columns/model_error_handling_spec.rb
```

### Running Tests with Specific Tags

```bash
# Run only real Rails environment tests
bundle exec rspec --tag real_rails

# Run only performance tests
bundle exec rspec --tag performance

# Run only security tests
bundle exec rspec --tag security

# Exclude long-running tests
bundle exec rspec --tag ~slow
```

### Advanced Test Running Options

#### Output Formats

```bash
# Default progress dots
bundle exec rspec

# Detailed test descriptions
bundle exec rspec --format documentation

# Simple progress with failures
bundle exec rspec --format progress

# Generate HTML report
bundle exec rspec --format html --out tmp/rspec_results.html

# JSON output for CI integration
bundle exec rspec --format json --out tmp/rspec_results.json
```

#### Coverage and Profiling

```bash
# Run with coverage report (already enabled by default)
bundle exec rspec
# Results in coverage/index.html

# Profile slow tests (show top 10 slowest)
bundle exec rspec --profile 10

# Profile memory usage (requires custom setup)
RUBY_PROF=1 bundle exec rspec spec/saltbox/sort_by_columns/model_*.rb
```

#### Debugging and Failure Analysis

```bash
# Stop on first failure
bundle exec rspec --fail-fast

# Only run failed tests from last run
bundle exec rspec --only-failures

# Run tests in random order (find order dependencies)
bundle exec rspec --order random

# Run with specific seed for reproducibility
bundle exec rspec --seed 12345

# Verbose output with backtraces
bundle exec rspec --backtrace

# Run specific test by line number
bundle exec rspec spec/saltbox/sort_by_columns/model_basic_spec.rb:45
```

#### Parallel Testing

```bash
# Install parallel_tests gem first
# gem install parallel_tests

# Run tests in parallel (faster on multi-core systems)
parallel_rspec spec/

# Run specific test suite in parallel
parallel_rspec spec/saltbox/sort_by_columns/
```

#### CI-Specific Commands

```bash
# Complete CI test run with coverage
CI=1 bundle exec rspec --format progress --format json --out tmp/rspec_results.json

# Test run for code quality checks
bundle exec rspec --format documentation --dry-run  # Validate test structure
bundle exec standardrb --fix                        # Auto-fix code style
bundle exec rspec                                   # Run full suite
```

### Targeted Testing Workflows

#### Development Workflow

```bash
# 1. Quick smoke test after changes
bundle exec rspec spec/saltbox/sort_by_columns/sort_by_columns_spec.rb

# 2. Test specific component you're working on
bundle exec rspec spec/saltbox/sort_by_columns/model_basic_spec.rb

# 3. Run related integration tests
bundle exec rspec spec/integration/

# 4. Full test suite before commit
bundle exec rspec
```

#### Debugging Failing Tests

```bash
# 1. Run only the failing test with verbose output
bundle exec rspec spec/path/to/failing_spec.rb:123 --backtrace

# 2. Check if it's environment-related
RAILS_ENV=development bundle exec rspec spec/path/to/failing_spec.rb:123
RAILS_ENV=production bundle exec rspec spec/path/to/failing_spec.rb:123

# 3. Run with debug output
DEBUG=1 bundle exec rspec spec/path/to/failing_spec.rb:123

# 4. Isolate the test (check for ordering dependencies)
bundle exec rspec spec/path/to/failing_spec.rb:123 --order random
```

#### Performance Testing Workflow

```bash
# 1. Run performance-related tests
bundle exec rspec spec/saltbox/sort_by_columns/model_error_handling_spec.rb \
                  spec/integration/controller_integration_spec.rb \
                  --tag performance

# 2. Profile memory usage
bundle exec rspec spec/integration/ --profile 5

# 3. Test with large datasets (if available)
LARGE_DATASET=1 bundle exec rspec spec/integration/
```

#### Security Testing Workflow

```bash
# 1. Run security-focused tests
bundle exec rspec --tag security

# 2. Test parameter pollution scenarios
bundle exec rspec spec/integration/controller_integration_spec.rb \
                  -e "parameter pollution"

# 3. Test SQL injection prevention
bundle exec rspec spec/saltbox/sort_by_columns/model_edge_cases_spec.rb \
                  -e "injection"
```

### Custom Test Commands

You can create custom rake tasks or shell scripts for common testing workflows:

```ruby
# lib/tasks/test_custom.rake
namespace :test do
  desc "Run core functionality tests"
  task :core do
    sh "bundle exec rspec spec/saltbox/sort_by_columns/model_basic_spec.rb " \
       "spec/saltbox/sort_by_columns/controller_spec.rb " \
       "spec/saltbox/sort_by_columns/railtie_spec.rb"
  end

  desc "Run security and edge case tests"
  task :security do
    sh "bundle exec rspec spec/saltbox/sort_by_columns/model_edge_cases_spec.rb " \
       "spec/integration/controller_integration_spec.rb " \
       "--tag security"
  end

  desc "Run integration tests only"
  task :integration do
    sh "bundle exec rspec spec/integration/"
  end

  desc "Run fast tests for TDD workflow"
  task :fast do
    sh "bundle exec rspec spec/saltbox/sort_by_columns/sort_by_columns_spec.rb " \
       "spec/saltbox/sort_by_columns/model_basic_spec.rb " \
       "--fail-fast"
  end
end
```

```bash
# Usage:
bundle exec rake test:core
bundle exec rake test:security
bundle exec rake test:integration
bundle exec rake test:fast
```

## Test Patterns and Conventions

### 1. Descriptive Test Organization

```ruby
RSpec.describe "Saltbox::SortByColumns::Model" do
  describe ".sort_by_columns" do
    context "when given valid column names" do
      it "stores column names as symbols" do
        # Test implementation
      end
    end

    context "when given mixed string and symbol inputs" do
      it "normalizes all inputs to symbols" do
        # Test implementation
      end
    end
  end
end
```

**Pattern**: Use clear describe/context/it structure with descriptive names that explain the scenario and expected behavior.

### 2. Environment-Aware Testing

```ruby
context "in development environment" do
  before { allow(Rails.env).to receive(:local?).and_return(true) }

  it "raises ArgumentError for invalid columns" do
    expect { test_model_class.sorted_by_columns("invalid_column:asc") }
      .to raise_error(ArgumentError, /Column 'invalid_column' not found/)
  end
end

context "in production environment" do
  before { allow(Rails.env).to receive(:local?).and_return(false) }

  it "logs warning and continues for invalid columns" do
    expect(Rails.logger).to receive(:warn).with(/Invalid sort column/)
    result = test_model_class.sorted_by_columns("invalid_column:asc")
    expect(result).to eq(test_model_class)
  end
end
```

**Pattern**: Test different behaviors based on Rails environment using mocked environment detection.

### 3. SQL Generation Verification

```ruby
it "generates correct SQL for association columns" do
  result = test_model_class.sorted_by_columns("category__name:asc")
  
  # Verify SQL structure
  expect(result.to_sql).to include("LEFT OUTER JOIN")
  expect(result.to_sql).to include("categories.name ASC NULLS LAST")
  expect(result.to_sql).to include("AS categories")
end
```

**Pattern**: Verify actual SQL generation for critical sorting operations, especially for associations and complex scenarios.

### 4. Mock Model Pattern

```ruby
let(:test_model_class) do
  Class.new do
    include Saltbox::SortByColumns::Model

    def self.name
      "TestModel"
    end

    def self.table_name
      "test_models"
    end

    def self.left_outer_joins(*args)
      self
    end

    def self.order(*args)
      self
    end

    def self.reflect_on_association(name)
      # Mock association reflection
    end

    sort_by_columns :name, :created_at, :category__name
  end
end
```

**Pattern**: Create minimal mock models that include the required behavior for testing without depending on actual ActiveRecord models.

### 5. Real Rails Integration Testing

```ruby
it "works with real ActiveRecord models and database", :real_rails do
  user = User.create!(name: "Test User", email: "test@example.com")
  
  result = User.sorted_by_columns("name:desc")
  expect(result).to be_a(ActiveRecord::Relation)
  expect(result.to_a).to include(user)
end
```

**Pattern**: Use the Combustion test Rails app for integration testing with real ActiveRecord models and database operations.

### 6. Error Scenario Testing

```ruby
context "when custom scope raises an exception" do
  before do
    allow(test_model_class).to receive(:sorted_by_popularity)
      .and_raise(StandardError.new("Database connection failed"))
  end

  context "in development environment" do
    before { allow(Rails.env).to receive(:local?).and_return(true) }

    it "allows the exception to propagate" do
      expect { test_model_class.sorted_by_columns("c_popularity:asc") }
        .to raise_error(StandardError, "Database connection failed")
    end
  end

  context "in production environment" do
    before { allow(Rails.env).to receive(:local?).and_return(false) }

    it "logs the error and returns the original scope" do
      expect(Rails.logger).to receive(:warn)
      result = test_model_class.sorted_by_columns("c_popularity:asc")
      expect(result).to eq(test_model_class)
    end
  end
end
```

**Pattern**: Test both happy path and error scenarios, with different expectations based on environment.

### 7. Performance and Security Testing

```ruby
it "handles parameter pollution attacks safely" do
  array_params = [
    ["name:asc", "'; DROP TABLE users; --"],
    ["name:asc", "id:desc", "malicious_column:asc"]
  ]
  
  expect { test_model_class.sorted_by_columns(array_params) }
    .not_to raise_error
  
  # Verify that only valid columns are processed
  result = test_model_class.sorted_by_columns(array_params)
  expect(result.to_sql).to include("name ASC")
  expect(result.to_sql).not_to include("DROP TABLE")
end

it "processes very long parameter strings efficiently" do
  long_param = Array.new(1000, "name:asc").join(",")
  
  expect { test_model_class.sorted_by_columns(long_param) }
    .not_to raise_error
end
```

**Pattern**: Test security scenarios and performance edge cases to ensure robust production behavior.

## Examples for Consuming Applications

### Basic Model Testing

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe "sorting functionality" do
    # Use shared examples for consistent testing
    it_behaves_like "sortable by columns", {
      allowed_columns: [:name, :email, :created_at],
      disallowed_column: :password,
      associated_column: {
        name: :organization__name,
        expected_sql: "organizations.name"
      }
    }
    
    # Test custom scopes specific to your model
    context "custom scope sorting" do
      before do
        user1 = create(:user)
        user2 = create(:user)
        create_list(:order, 3, user: user1)
        create_list(:order, 1, user: user2)
      end

      it "sorts by total orders correctly" do
        result = User.sorted_by_columns("c_total_orders:desc")
        users = result.to_a
        
        expect(users.first.orders.count).to be > users.last.orders.count
      end
    end
  end
end
```

### Controller Testing

```ruby
# spec/controllers/users_controller_spec.rb
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe "GET #index" do
    let!(:user1) { create(:user, name: "Alice") }
    let!(:user2) { create(:user, name: "Bob") }

    context "with sort parameter" do
      it "sorts users by name ascending" do
        get :index, params: { sort: "name:asc" }
        
        expect(assigns(:users).to_a).to eq([user1, user2])
      end

      it "sorts users by name descending" do
        get :index, params: { sort: "name:desc" }
        
        expect(assigns(:users).to_a).to eq([user2, user1])
      end
    end

    context "with invalid sort parameter" do
      it "handles invalid columns gracefully in production" do
        allow(Rails.env).to receive(:local?).and_return(false)
        
        expect { get :index, params: { sort: "invalid_column:asc" } }
          .not_to raise_error
      end
    end
  end
end
```

### Request Testing

```ruby
# spec/requests/api/users_spec.rb
require 'rails_helper'

RSpec.describe "API::Users", type: :request do
  let!(:users) { create_list(:user, 3) }

  describe "GET /api/users" do
    context "with sorting parameters" do
      it "returns users sorted by name" do
        get "/api/users", params: { sort: "name:asc" }
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        names = json_response["users"].map { |u| u["name"] }
        expect(names).to eq(names.sort)
      end

      it "returns users with association sorting" do
        get "/api/users", params: { sort: "organization__name:desc" }
        
        expect(response).to have_http_status(:ok)
        # Verify that LEFT OUTER JOIN was used to include users without organizations
      end
    end

    context "with multiple sort parameters" do
      it "handles comma-separated sort columns" do
        get "/api/users", params: { sort: "name:asc,created_at:desc" }
        
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid sort parameters" do
      it "handles malformed parameters gracefully" do
        get "/api/users", params: { sort: "invalid_column:asc" }
        
        # Should not raise error in any environment
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
```

### Feature Testing

```ruby
# spec/features/user_sorting_spec.rb
require 'rails_helper'

RSpec.feature "User sorting", type: :feature, js: true do
  let!(:users) do
    [
      create(:user, name: "Charlie", created_at: 2.days.ago),
      create(:user, name: "Alice", created_at: 1.day.ago),
      create(:user, name: "Bob", created_at: Time.current)
    ]
  end

  scenario "User can sort by name" do
    visit users_path
    
    click_link "Sort by Name"
    
    # Verify sorting worked
    user_names = page.all(".user-name").map(&:text)
    expect(user_names).to eq(["Alice", "Bob", "Charlie"])
  end

  scenario "User can sort by creation date" do
    visit users_path
    
    click_link "Sort by Date"
    
    # Verify reverse chronological order
    user_names = page.all(".user-name").map(&:text)
    expect(user_names).to eq(["Bob", "Alice", "Charlie"])
  end

  scenario "URL parameters are preserved during sorting" do
    visit users_path(search: "test", page: 2)
    
    click_link "Sort by Name"
    
    # Verify other parameters are maintained
    expect(current_url).to include("search=test")
    expect(current_url).to include("sort=name")
  end
end
```

## Complex Test Cases Documentation

### 1. Parameter Pollution Testing

**Purpose**: Ensure the gem safely handles malicious array parameters that could be used in parameter pollution attacks.

```ruby
it "handles parameter pollution attacks safely" do
  # Simulate parameter pollution where sort parameter is sent as an array
  array_params = [
    ["name:asc", "'; DROP TABLE users; --"],
    ["name:asc", "id:desc", "malicious_column:asc"],
    ["legitimate:asc", "'; DROP TABLE users; --:desc"],
    [nil, "name:asc", "", "category__name:desc"]
  ]
  
  expect { test_model_class.sorted_by_columns(array_params) }
    .not_to raise_error
  
  result = test_model_class.sorted_by_columns(array_params)
  
  # Verify that only the first valid string is processed
  expect(result.to_sql).to include("name ASC")
  expect(result.to_sql).not_to include("DROP TABLE")
  expect(result.to_sql).not_to include("malicious")
end
```

**Key Points**:
- Tests protection against parameter pollution attacks
- Verifies that only the first valid string element is processed
- Ensures malicious SQL is never executed
- Added array handling protection in model code during Phase 6

### 2. Concurrent Request Testing

**Purpose**: Verify thread safety and proper behavior under concurrent access patterns.

```ruby
it "handles concurrent requests safely" do
  threads = []
  errors = []
  
  # Simulate concurrent requests
  10.times do |i|
    threads << Thread.new do
      begin
        if i.even?
          test_model_class.sorted_by_columns("name:asc")
        else
          test_model_class.sorted_by_columns("category__name:desc")
        end
      rescue => e
        errors << e
      end
    end
  end
  
  threads.each(&:join)
  expect(errors).to be_empty
end
```

**Key Points**:
- Tests thread safety under concurrent access
- Verifies no race conditions in sorting logic
- Important for production Rails applications with multiple threads

### 3. Memory Efficiency Testing

**Purpose**: Ensure the gem doesn't create memory leaks with repeated calls or large datasets.

```ruby
it "processes large numbers of calls efficiently" do
  # Test memory usage doesn't grow unbounded
  initial_memory = get_memory_usage
  
  1000.times do |i|
    test_model_class.sorted_by_columns("name:asc,category__name:desc")
  end
  
  final_memory = get_memory_usage
  memory_growth = final_memory - initial_memory
  
  # Memory growth should be minimal (under 10MB for this test)
  expect(memory_growth).to be < 10_000_000
end
```

**Key Points**:
- Tests for memory leaks in repeated operations
- Important for long-running Rails applications
- Verifies efficient string parsing and SQL generation

### 4. Rails Environment Detection Testing

**Purpose**: Test proper behavior detection across different Rails environments and edge cases.

```ruby
context "when Rails.env.local? is undefined" do
  before do
    allow(Rails.env).to receive(:respond_to?).with(:local?).and_return(false)
  end

  it "falls back to development environment detection" do
    allow(Rails.env).to receive(:development?).and_return(true)
    
    expect { test_model_class.sorted_by_columns("invalid_column:asc") }
      .to raise_error(ArgumentError)
  end
end

context "when Rails.env.local? returns non-boolean" do
  before do
    allow(Rails.env).to receive(:local?).and_return("maybe")
  end

  it "treats truthy values as development environment" do
    expect { test_model_class.sorted_by_columns("invalid_column:asc") }
      .to raise_error(ArgumentError)
  end
end
```

**Key Points**:
- Tests environment detection edge cases
- Handles different Rails versions and configurations
- Provides fallback behavior for non-standard setups

## Best Practices for Consumer Testing

### 1. Use Shared Examples

The gem provides comprehensive shared examples that cover most common scenarios:

```ruby
it_behaves_like "sortable by columns", {
  allowed_columns: [:name, :email, :created_at],
  disallowed_column: :password,
  associated_column: {
    name: :organization__name,
    expected_sql: "organizations.name"
  }
}
```

### 2. Test Both Happy Path and Error Scenarios

```ruby
describe "custom scope sorting" do
  context "when scope exists and works" do
    it "applies custom sorting logic" do
      # Test successful case
    end
  end

  context "when scope doesn't exist" do
    it "handles missing scope gracefully" do
      # Test error case
    end
  end
end
```

### 3. Test Environment-Specific Behavior

```ruby
context "in development" do
  before { allow(Rails.env).to receive(:local?).and_return(true) }
  
  it "raises errors for debugging" do
    # Test development behavior
  end
end

context "in production" do
  before { allow(Rails.env).to receive(:local?).and_return(false) }
  
  it "logs warnings and continues" do
    # Test production behavior
  end
end
```

### 4. Test Integration with Other Gems

```ruby
it "works with kaminari pagination" do
  result = User.sorted_by_columns("name:asc").page(1).per(10)
  expect(result).to be_a(Kaminari::PaginatableArray)
end

it "works with ransack search" do
  result = User.ransack(name_cont: "test").result
                .sorted_by_columns("created_at:desc")
  expect(result).to be_a(ActiveRecord::Relation)
end
```

### 5. Test Real Database Scenarios

```ruby
it "handles NULL values in associations correctly" do
  user_with_org = create(:user, organization: create(:organization, name: "ABC Corp"))
  user_without_org = create(:user, organization: nil)
  
  result = User.sorted_by_columns("organization__name:asc").to_a
  
  # Users without organizations should appear last (NULLS LAST)
  expect(result).to eq([user_with_org, user_without_org])
end
```

## Test Dependencies

### Required Gems for Testing

```ruby
# Gemfile
group :development, :test do
  gem "rails", "~> 8.0"
  gem "sqlite3", "~> 2.1"
  gem "combustion", "~> 1.5"        # Rails test app framework
  gem "has_scope", "~> 0.8.0"       # Controller integration
  gem "simplecov", "~> 0.22.0"      # Code coverage
  gem "benchmark-ips", "~> 2.12"    # Performance testing
  gem "memory_profiler", "~> 1.0"   # Memory leak detection
end
```

### Test Configuration Files

- `spec/spec_helper.rb` - Basic RSpec configuration and SimpleCov setup
- `spec/rails_helper.rb` - Rails-specific configuration and Combustion setup
- `spec/rails_app/` - Minimal Rails application for integration testing
- `spec/support/` - Shared examples and helper methods

## Troubleshooting Tests

### Common Issues and Solutions

1. **Tests failing with "uninitialized constant" errors**
   - Ensure `rails_helper` is required instead of `spec_helper` for Rails tests
   - Check that the Combustion test app is properly configured

2. **SQL-related test failures**
   - Verify that the test database is properly set up
   - Check that migrations in `spec/rails_app/db/` are current

3. **Environment-specific test failures**
   - Ensure Rails environment mocking is consistent
   - Check that `Rails.env.local?` behavior is properly stubbed

4. **Performance test inconsistencies**
   - Run performance tests in isolation when possible
   - Consider system load when evaluating performance thresholds

### Debug Helpers

```ruby
# Debug SQL generation
puts result.to_sql

# Debug includes/joins
puts result.includes_values.inspect
puts result.joins_values.inspect

# Debug environment detection
puts "Rails.env.local?: #{Rails.env.local?}"
puts "Rails.env.development?: #{Rails.env.development?}"
```

## Conclusion

This comprehensive testing approach ensures that the Saltbox::SortByColumns gem is robust, secure, and production-ready. The test suite covers all scenarios from basic functionality to complex edge cases, providing confidence in the gem's reliability across different Rails environments and use cases.

For questions about testing or to contribute additional test scenarios, please refer to the main README.md or open an issue on the project repository. 
