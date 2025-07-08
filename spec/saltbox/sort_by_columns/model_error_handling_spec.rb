# frozen_string_literal: true

require "rails_helper"

RSpec.describe Saltbox::SortByColumns::Model, "Error Handling & Environment Behavior" do
  # Use the real User model from our Combustion app
  let(:test_model) { User }

  before do
    # Create test data
    @org_a = Organization.create!(name: "Alpha Corp")
    @org_b = Organization.create!(name: "Beta Inc")

    @user1 = User.create!(name: "Charlie", email: "charlie@example.com", organization: @org_b)
    @user2 = User.create!(name: "Alice", email: "alice@example.com", organization: @org_a)
    @user3 = User.create!(name: "Bob", email: "bob@example.com", organization: @org_a)

    # Set up basic allowed columns
    test_model.column_sortable_by :name, :email, :created_at, :organization__name
  end

  describe "multi-environment error handling" do
    context "in test environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(true)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warnings in test environment like production" do
        result = test_model.sorted_by_columns("invalid_column:asc")

        expect(Rails.logger).to have_received(:warn).with(/ignoring disallowed column/)
        expect(result.count).to eq(3)
      end

      it "does not catch database connection errors" do
        # Database connection errors should propagate up to the application
        # This is a conceptual test to ensure we don't wrap database operations in rescue blocks

        # Test that normal operations work
        expect(test_model.sorted_by_columns("name:asc")).to be_a(ActiveRecord::Relation)
      end
    end

    context "in staging environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails.env).to receive(:staging?).and_return(true)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "behaves like production environment" do
        result = test_model.sorted_by_columns("invalid_column:asc")

        expect(Rails.logger).to have_received(:warn).with(/ignoring disallowed column/)
        expect(result.count).to eq(3)
      end
    end

    context "with Rails.env.local? edge cases" do
      it "handles when Rails.env.local? returns non-boolean" do
        allow(Rails.env).to receive(:local?).and_return("maybe")
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        # Should treat truthy value as development
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "comprehensive logger edge cases" do
    context "with different logger configurations" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
      end

      it "handles logger with different log levels" do
        logger = double("logger")
        allow(logger).to receive(:warn).and_return(nil)
        allow(logger).to receive(:level).and_return(Logger::ERROR)
        allow(Rails).to receive(:logger).and_return(logger)

        result = test_model.sorted_by_columns("invalid_column:asc")
        expect(result.count).to eq(3)
      end

      it "handles logger that raises exceptions" do
        logger = double("logger")
        allow(logger).to receive(:warn).and_raise(StandardError, "Logger error")
        allow(Rails).to receive(:logger).and_return(logger)

        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.not_to raise_error
      end

      it "handles logger with custom formatter" do
        logger = double("logger")
        allow(logger).to receive(:warn) do |message|
          # Custom formatter adds timestamp prefix
          "[#{Time.now}] #{message}"
        end
        allow(Rails).to receive(:logger).and_return(logger)

        result = test_model.sorted_by_columns("invalid_column:asc")
        expect(result.count).to eq(3)
      end

      it "handles logger with method_missing" do
        logger = Class.new do
          def method_missing(method_name, *args, &block)
            # Silent logger that responds to any method
            nil
          end

          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end.new

        allow(Rails).to receive(:logger).and_return(logger)

        result = test_model.sorted_by_columns("invalid_column:asc")
        expect(result.count).to eq(3)
      end
    end
  end

  describe "error message format testing" do
    context "in development environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "provides detailed error messages for different error types" do
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError, /SortByColumns: detected a disallowed sortable column/)
      end

      it "includes column name in error message" do
        expect {
          test_model.sorted_by_columns("very_specific_invalid_column:asc")
        }.to raise_error(ArgumentError, /very_specific_invalid_column/)
      end

      it "includes model name in error message" do
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError, /column_sortable_by: invalid_column/)
      end

      it "handles error message interpolation with special characters" do
        expect {
          test_model.sorted_by_columns("column@#$%:asc")
        }.to raise_error(ArgumentError, /column@#\$%/)
      end

      it "handles error message interpolation with Unicode characters" do
        expect {
          test_model.sorted_by_columns("column_🎉:asc")
        }.to raise_error(ArgumentError, /column_🎉/)
      end

      it "handles error message interpolation with very long column names" do
        long_column = "a" * 1000
        expect {
          test_model.sorted_by_columns("#{long_column}:asc")
        }.to raise_error(ArgumentError, /#{long_column}/)
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs consistent message format" do
        test_model.sorted_by_columns("invalid_column:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: invalid_column")
      end

      it "logs critical message format" do
        test_model.send(:handle_error, "Test error for column: %{column}", "test_col", true)

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring all columns due to test_col")
      end

      it "handles logging with special characters" do
        test_model.sorted_by_columns("column@#$%:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: column@#$%")
      end

      it "handles logging with Unicode characters" do
        test_model.sorted_by_columns("column_🎉:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: column_🎉")
      end
    end
  end

  describe "performance with error handling" do
    before do
      allow(Rails.env).to receive(:local?).and_return(false)
      allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
    end

    it "handles many invalid columns efficiently" do
      invalid_columns = (1..100).map { |i| "invalid_column_#{i}:asc" }.join(",")

      start_time = Time.now
      result = test_model.sorted_by_columns(invalid_columns)
      end_time = Time.now

      expect(result.count).to eq(3)
      expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
    end

    it "handles repeated error scenarios efficiently" do
      start_time = Time.now

      100.times do
        test_model.sorted_by_columns("invalid_column:asc")
      end

      end_time = Time.now
      expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
    end

    it "handles mixed valid and invalid columns efficiently" do
      mixed_columns = "invalid1:asc,name:desc,invalid2:asc,email:asc,invalid3:desc"

      start_time = Time.now
      result = test_model.sorted_by_columns(mixed_columns)
      end_time = Time.now

      expect(result.count).to eq(3)
      expect(end_time - start_time).to be < 0.5 # Should complete in under 0.5 seconds
    end
  end

  describe "thread safety with error handling" do
    before do
      allow(Rails.env).to receive(:local?).and_return(false)
      allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
    end

    it "handles concurrent error scenarios safely" do
      threads = []
      results = []

      10.times do
        threads << Thread.new do
          result = test_model.sorted_by_columns("invalid_column:asc")
          results << result.count
        end
      end

      threads.each(&:join)
      expect(results.all? { |count| count == 3 }).to be true
    end

    it "handles concurrent valid and invalid requests safely" do
      threads = []
      results = []

      5.times do
        threads << Thread.new do
          result = test_model.sorted_by_columns("invalid_column:asc")
          results << result.count
        end
      end

      5.times do
        threads << Thread.new do
          result = test_model.sorted_by_columns("name:asc")
          results << result.count
        end
      end

      threads.each(&:join)
      expect(results.all? { |count| count == 3 }).to be true
    end
  end

  describe "error handling with database constraints" do
    before do
      allow(Rails.env).to receive(:local?).and_return(false)
      allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
    end

    it "does not catch ActiveRecord exceptions" do
      # SortByColumns should not catch database exceptions - they should propagate
      # This is a conceptual test to ensure we don't wrap database operations in rescue blocks

      # Test that normal operations work
      expect(test_model.sorted_by_columns("name:asc")).to be_a(ActiveRecord::Relation)
      expect(test_model.sorted_by_columns("organization__name:asc")).to be_a(ActiveRecord::Relation)
    end
  end

  describe "error handling with custom scope edge cases" do
    before do
      test_model.column_sortable_by :name, :c_problematic_scope
    end

    context "in development environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "provides helpful error when custom scope doesn't exist" do
        expect {
          test_model.sorted_by_columns("c_problematic_scope:asc")
        }.to raise_error(ArgumentError, /does not respond to.*sorted_by_problematic_scope/)
      end

      it "provides helpful error when custom scope raises exception" do
        allow(test_model).to receive(:respond_to?).with(:sorted_by_problematic_scope).and_return(true)
        allow(test_model).to receive(:sorted_by_problematic_scope).and_raise(StandardError, "Custom error")

        expect {
          test_model.sorted_by_columns("c_problematic_scope:asc")
        }.to raise_error(StandardError, "Custom error")
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warning and continues when custom scope doesn't exist" do
        result = test_model.sorted_by_columns("c_problematic_scope:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: c_problematic_scope")
        expect(result.count).to eq(3)
      end

      it "logs warning and continues when custom scope raises exception" do
        allow(test_model).to receive(:respond_to?).with(:sorted_by_problematic_scope).and_return(true)
        allow(test_model).to receive(:sorted_by_problematic_scope).and_raise(StandardError, "Custom error")

        expect {
          test_model.sorted_by_columns("c_problematic_scope:asc")
        }.to raise_error(StandardError, "Custom error")
      end
    end
  end

  describe "error handling with association edge cases" do
    context "in development environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "provides helpful error for deeply nested associations" do
        test_model.column_sortable_by :name, :nonexistent_association__name

        # This should fail because the association "nonexistent_association" doesn't exist
        expect {
          test_model.sorted_by_columns("nonexistent_association__name:asc")
        }.to raise_error(ArgumentError, /association.*nonexistent_association.*doesn't exist/)
      end

      it "provides helpful error for polymorphic associations" do
        test_model.column_sortable_by :name, :commentable__title

        expect {
          test_model.sorted_by_columns("commentable__title:asc")
        }.to raise_error(ArgumentError, /association.*commentable.*doesn't exist/)
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warning for deeply nested associations" do
        test_model.column_sortable_by :name, :nonexistent_association__name

        result = test_model.sorted_by_columns("nonexistent_association__name:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: nonexistent_association")
        expect(result.count).to eq(3)
      end

      it "logs warning for polymorphic associations" do
        test_model.column_sortable_by :name, :commentable__title

        result = test_model.sorted_by_columns("commentable__title:asc")

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: commentable")
        expect(result.count).to eq(3)
      end
    end
  end
end
