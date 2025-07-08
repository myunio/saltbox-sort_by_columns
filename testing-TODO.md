# Testing TODO for Saltbox::SortByColumns

This document outlines the comprehensive testing plan to improve test coverage for the saltbox-sort_by_columns gem.

## Overview
**Current State**: 32 lines of basic integration tests  
**Goal**: Comprehensive unit and integration test coverage  
**Target**: 90%+ code coverage with edge case handling  

---

## Phase 1: Foundation - Core Unit Tests 🏗️

### Model Module Core Functionality
- [x] Create `spec/saltbox/sort_by_columns/model_spec.rb`
- [x] Test `.column_sortable_by` method
  - [x] Stores allowed fields as symbols
  - [x] Overwrites previous allowed fields
  - [x] Handles string and symbol inputs
  - [x] Handles empty input
- [x] Test `.column_sortable_allowed_fields` method
  - [x] Returns empty array when none set
  - [x] Returns correct array of symbols
- [x] Test `.normalize_direction` private method
  - [x] Returns "asc" for valid "asc"
  - [x] Returns "desc" for valid "desc"
  - [x] Defaults to "asc" for invalid values
  - [x] Defaults to "asc" for nil
  - [x] Handles case sensitivity
- [x] **BONUS**: Fixed actual bug - nil Rails.logger handling

### Controller Module Core Functionality
- [x] Create `spec/saltbox/sort_by_columns/controller_spec.rb`
- [x] Test module inclusion
  - [x] Includes has_scope with correct parameters
  - [x] Defines scope only for :index action
  - [x] Uses :sort as the parameter name
  - [x] Verifies has_scope gem integration

### Railtie Testing
- [x] Create `spec/saltbox/sort_by_columns/railtie_spec.rb`
- [x] Test railtie configuration
  - [x] Sets correct railtie name
  - [x] Initializes configuration options
  - [x] Loads only when Rails is defined

**✅ PHASE 1 COMPLETE: 54 passing tests, 0 failures**
- **Model tests**: 28 tests (including bug fix for nil Rails.logger)
- **Controller tests**: 14 tests (including has_scope integration)
- **Railtie tests**: 12 tests (including Rails configuration)

---

## Phase 2: Edge Cases & Input Validation 🛡️

### Input Validation Edge Cases
- [x] Add edge case tests to model_spec.rb
- [x] Test `.sorted_by_columns` with invalid inputs
  - [x] Handles nil input
  - [x] Handles empty string input
  - [x] Handles whitespace-only input
  - [x] Handles malformed column specifications
  - [x] Handles columns with special characters
  - [x] Handles very long column names
  - [x] Handles columns with no direction specified
  - [x] Handles columns with invalid directions
  - [x] Handles multiple consecutive commas
  - [x] Handles trailing/leading commas
  - [x] Handles columns with extra colons

### Association Column Edge Cases
- [x] Test association column parsing
  - [x] Handles association names with multiple underscores
  - [x] Handles missing column part after `__`
  - [x] Handles empty association name before `__`
  - [x] Handles malformed association syntax
  - [x] Handles non-existent associations
  - [x] Handles valid associations with invalid columns

### Custom Scope Edge Cases
- [x] Test custom scope validation
  - [x] Handles missing `c_` prefix validation
  - [x] Handles multiple custom scope columns (should fail)
  - [x] Handles custom scopes mixed with regular columns
  - [x] Handles non-existent custom scope methods
  - [x] Handles custom scopes not in allowed fields

**✅ PHASE 2 COMPLETE: 128 passing tests, 0 failures**
- **Model tests**: 77 tests (including comprehensive edge cases)
- **Controller tests**: 14 tests 
- **Railtie tests**: 12 tests
- **Integration tests**: 19 tests (including real Rails environment edge cases)
- **Basic integration tests**: 6 tests

---

## Phase 3: Error Handling & Environment Behavior 🚨

### Environment-Specific Error Handling
- [ ] Create comprehensive error handling tests
- [ ] Test development environment behavior
  - [ ] Raises ArgumentError for disallowed columns
  - [ ] Raises ArgumentError for invalid associations
  - [ ] Raises ArgumentError for multiple custom scope columns
  - [ ] Provides helpful error messages with suggestions
- [ ] Test production environment behavior
  - [ ] Logs warnings for disallowed columns
  - [ ] Continues processing valid columns when some invalid
  - [ ] Returns unmodified relation when all columns invalid
  - [ ] Silently ignores invalid custom scopes
- [ ] Test logging edge cases
  - [ ] Handles nil Rails.logger gracefully
  - [ ] Handles missing logger methods
  - [ ] Verifies correct warning message format

### Error Message Testing
- [ ] Test `.handle_error` private method
  - [ ] Interpolates column names correctly
  - [ ] Handles different error types
  - [ ] Provides actionable error messages
  - [ ] Handles critical vs non-critical errors

---

## Phase 4: SQL Generation & Association Testing 🔧

### SQL Generation Verification
- [ ] Create detailed SQL output tests
- [ ] Test standard column SQL generation
  - [ ] Generates proper table prefixes for local columns
  - [ ] Maintains column order in ORDER BY clause
  - [ ] Properly quotes table and column names
  - [ ] Handles mixed ASC/DESC directions
- [ ] Test association column SQL generation
  - [ ] Generates LEFT OUTER JOIN for associations
  - [ ] Applies NULLS LAST for ASC associations
  - [ ] Applies NULLS FIRST for DESC associations
  - [ ] Uses association name as table alias
  - [ ] Handles multiple associations without duplicate joins
  - [ ] Handles custom class_name associations

### Association Processing
- [ ] Test `.process_association_column` private method
  - [ ] Correctly parses association__column format
  - [ ] Validates association existence via reflection
  - [ ] Builds correct includes array
  - [ ] Generates proper order fragments
  - [ ] Handles association reflection errors

### Sorting Application
- [ ] Test `.apply_sorting` private method
  - [ ] Applies left_outer_joins correctly
  - [ ] Builds proper ORDER BY clause
  - [ ] Uses Arel.sql for order fragments
  - [ ] Handles empty includes array
  - [ ] Handles empty order fragments

---

## Phase 5: Advanced Features & Custom Scopes 🎯

### Custom Scope Comprehensive Testing
- [ ] Test `.handle_custom_scope` private method
  - [ ] Strips `c_` prefix correctly
  - [ ] Calls correct scope method with direction
  - [ ] Validates custom scope in allowed fields
  - [ ] Prevents mixing with other columns
  - [ ] Handles missing scope methods gracefully
- [ ] Test custom scope integration
  - [ ] Works with real model scopes
  - [ ] Passes direction parameter correctly
  - [ ] Returns proper ActiveRecord::Relation

### Standard Column Processing
- [ ] Test `.process_standard_columns` private method
  - [ ] Correctly splits and parses column specifications
  - [ ] Builds includes array for associations
  - [ ] Builds order fragments array
  - [ ] Skips disallowed columns appropriately
  - [ ] Handles mixed valid/invalid columns

---

## Phase 6: Integration & Real-World Testing 🌍

### Real Rails Integration
- [ ] Create `spec/integration/real_model_spec.rb`
- [ ] Set up test Rails models with associations
- [ ] Test with real ActiveRecord queries
  - [ ] Works with actual database sorting
  - [ ] Works with real associations (belongs_to, has_many)
  - [ ] Integrates with Rails query methods (includes, joins)
  - [ ] Works with pagination gems
- [ ] Test controller integration
  - [ ] Works with has_scope gem
  - [ ] Processes URL parameters correctly
  - [ ] Integrates with Rails parameter handling

### Shared Examples Validation
- [ ] Create `spec/support/shared_examples_spec.rb`
- [ ] Test shared examples functionality
  - [ ] Loads correctly when RSpec available
  - [ ] Provides comprehensive coverage
  - [ ] Works with different model configurations
  - [ ] Handles optional parameters correctly

---

## Phase 7: Performance, Security & Quality 🔒

### Performance Testing
- [ ] Add performance-focused tests
  - [ ] Handles very long sort parameter strings
  - [ ] Efficiently processes large numbers of allowed columns
  - [ ] Does not leak memory with repeated calls
  - [ ] Benchmarks against baseline performance

### Security Testing
- [ ] Add security-focused tests
  - [ ] Prevents SQL injection in column names
  - [ ] Validates input sanitization
  - [ ] Tests with malicious input patterns
  - [ ] Ensures safe SQL generation

### Test Quality & Coverage
- [ ] Add test infrastructure improvements
  - [ ] Set up code coverage reporting
  - [ ] Add test performance monitoring
  - [ ] Create helper methods for common test patterns
  - [ ] Add mutation testing for critical paths

---

## Phase 8: Documentation & Examples 📚

### Test Documentation
- [ ] Document test patterns and conventions
- [ ] Create examples for consuming applications
- [ ] Add inline documentation for complex test cases
- [ ] Document how to run specific test suites

### Test Coverage Verification
- [ ] Verify 90%+ code coverage achieved
- [ ] Ensure all public methods tested
- [ ] Ensure all private methods tested indirectly
- [ ] Ensure all error paths tested
- [ ] Ensure all environment behaviors tested

---

## Completion Checklist ✅

### Phase Completion
- [x] Phase 1: Foundation Complete ✅ (54 tests passing)
- [x] Phase 2: Edge Cases Complete ✅ (128 tests passing)
- [ ] Phase 3: Error Handling Complete
- [ ] Phase 4: SQL Generation Complete
- [ ] Phase 5: Advanced Features Complete
- [ ] Phase 6: Integration Complete
- [ ] Phase 7: Performance & Security Complete
- [ ] Phase 8: Documentation Complete

### Final Validation
- [ ] All tests passing consistently
- [ ] Code coverage above 90%
- [ ] Performance benchmarks acceptable
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Ready for production use

---

## Notes & Decisions

### Test Framework Decisions
- Using RSpec for consistency with existing tests
- Using shared examples pattern for reusability
- Mocking Rails environment for unit tests

### Coverage Goals
- **Unit Tests**: Test each method in isolation
- **Integration Tests**: Test real Rails interaction
- **Edge Cases**: Test all error conditions and malformed inputs
- **Performance**: Ensure acceptable performance under load
- **Security**: Prevent injection and validate all inputs

### Maintenance Strategy
- Keep tests independent and fast
- Use descriptive test names and contexts
- Group related tests logically
- Maintain test documentation alongside implementation
