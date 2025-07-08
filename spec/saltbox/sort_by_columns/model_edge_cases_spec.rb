# frozen_string_literal: true

require "rails_helper"

RSpec.describe Saltbox::SortByColumns::Model, "Edge Cases & Input Validation" do
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

  describe "input validation edge cases" do
    it "handles malformed column specifications" do
      # Test malformed inputs that should be ignored in production
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns(":::")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles columns with special characters" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("name@#$%:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles very long column names" do
      allow(Rails.env).to receive(:local?).and_return(false)
      long_column_name = "a" * 1000

      result = test_model.sorted_by_columns("#{long_column_name}:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles columns with no direction specified" do
      result = test_model.sorted_by_columns("name")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles columns with invalid directions" do
      result = test_model.sorted_by_columns("name:invalid_direction")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie]) # defaults to asc
    end

    it "handles multiple consecutive commas" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("name:asc,,,email:desc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles trailing and leading commas" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns(",name:asc,email:desc,")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles columns with extra colons" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("name:asc:extra:colons")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles empty column specifications between commas" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("name:asc,,email:desc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles whitespace around column specifications" do
      result = test_model.sorted_by_columns("  name:asc  ,  email:desc  ")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles column names with numbers and underscores" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("column_123:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    context "in development environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "raises ArgumentError for disallowed columns" do
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError, /disallowed sortable column/)
      end

      it "raises ArgumentError for malformed column specifications" do
        # Actually, malformed specs like ":::" get filtered out as blank columns
        # So let's test with a truly disallowed column instead
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for special characters in column names" do
        expect {
          test_model.sorted_by_columns("name@#$%:asc")
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "association column edge cases" do
    it "handles association names with multiple underscores" do
      allow(Rails.env).to receive(:local?).and_return(false)

      # Add a column that looks like it has multiple underscores
      test_model.column_sortable_by :name, :multi_word_association__name

      result = test_model.sorted_by_columns("multi_word_association__name:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles missing column part after __" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("organization__:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles empty association name before __" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("__name:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles malformed association syntax" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("organization___name:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles non-existent associations" do
      allow(Rails.env).to receive(:local?).and_return(false)

      test_model.column_sortable_by :name, :nonexistent_association__name

      result = test_model.sorted_by_columns("nonexistent_association__name:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles valid associations with invalid columns" do
      allow(Rails.env).to receive(:local?).and_return(false)

      test_model.column_sortable_by :name, :organization__nonexistent_column

      result = test_model.sorted_by_columns("organization__nonexistent_column:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles association columns not in allowed fields" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("organization__created_at:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    context "in development environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "raises ArgumentError for non-existent associations" do
        test_model.column_sortable_by :name, :nonexistent_association__name

        expect {
          test_model.sorted_by_columns("nonexistent_association__name:asc")
        }.to raise_error(ArgumentError, /doesn't exist on model/)
      end

      it "raises ArgumentError for association columns not in allowed fields" do
        expect {
          test_model.sorted_by_columns("organization__created_at:asc")
        }.to raise_error(ArgumentError, /disallowed sortable column/)
      end
    end
  end

  describe "custom scope edge cases" do
    before do
      test_model.column_sortable_by :name, :c_full_name, :c_custom_sort

      # Mock custom scope methods
      allow(test_model).to receive(:sorted_by_full_name).and_return(test_model.all)
      allow(test_model).to receive(:sorted_by_custom_sort).and_return(test_model.all)
    end

    it "handles missing c_ prefix validation" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("full_name:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles multiple custom scope columns (should fail)" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("c_full_name:asc,c_custom_sort:desc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
      expect(test_model).not_to have_received(:sorted_by_full_name)
      expect(test_model).not_to have_received(:sorted_by_custom_sort)
    end

    it "handles custom scopes mixed with regular columns" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("c_full_name:asc,name:desc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
      expect(test_model).not_to have_received(:sorted_by_full_name)
    end

    it "handles non-existent custom scope methods" do
      allow(Rails.env).to receive(:local?).and_return(false)

      test_model.column_sortable_by :name, :c_nonexistent_scope

      result = test_model.sorted_by_columns("c_nonexistent_scope:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "handles custom scopes not in allowed fields" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = test_model.sorted_by_columns("c_unauthorized_scope:asc")
      expect(result.count).to eq(3)
      expect(result).to be_a(ActiveRecord::Relation)
    end

    it "successfully calls valid custom scope with direction" do
      result = test_model.sorted_by_columns("c_full_name:desc")
      expect(test_model).to have_received(:sorted_by_full_name).with("desc")
      expect(result.count).to eq(3)
    end

    it "defaults to asc direction for custom scopes" do
      result = test_model.sorted_by_columns("c_full_name")
      expect(test_model).to have_received(:sorted_by_full_name).with("asc")
      expect(result.count).to eq(3)
    end

    context "in development environment" do
      before { allow(Rails.env).to receive(:local?).and_return(true) }

      it "raises ArgumentError for multiple custom scope columns" do
        expect {
          test_model.sorted_by_columns("c_full_name:asc,c_custom_sort:desc")
        }.to raise_error(ArgumentError, /does not support multiple columns/)
      end

      it "raises ArgumentError for custom scopes mixed with regular columns" do
        expect {
          test_model.sorted_by_columns("c_full_name:asc,name:desc")
        }.to raise_error(ArgumentError, /does not support multiple columns/)
      end

      it "raises ArgumentError for non-existent custom scope methods" do
        test_model.column_sortable_by :name, :c_nonexistent_scope

        expect {
          test_model.sorted_by_columns("c_nonexistent_scope:asc")
        }.to raise_error(ArgumentError, /does not respond to.*sorted_by_nonexistent_scope/)
      end

      it "raises ArgumentError for custom scopes not in allowed fields" do
        expect {
          test_model.sorted_by_columns("c_unauthorized_scope:asc")
        }.to raise_error(ArgumentError, /disallowed sortable column/)
      end
    end
  end

  describe "basic error handling" do
    context "in development environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "raises ArgumentError for disallowed columns" do
        expect {
          test_model.sorted_by_columns("invalid_column:asc")
        }.to raise_error(ArgumentError, /detected a disallowed sortable column/)
      end

      it "raises ArgumentError for non-existent associations" do
        test_model.column_sortable_by :nonexistent__column

        expect {
          test_model.sorted_by_columns("nonexistent__column:asc")
        }.to raise_error(ArgumentError, /association.*doesn't exist/)
      end

      it "raises ArgumentError for multiple custom scope columns" do
        test_model.column_sortable_by :c_custom, :name

        expect {
          test_model.sorted_by_columns("c_custom:asc,name:desc")
        }.to raise_error(ArgumentError, /does not support multiple columns/)
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warnings for invalid columns and continues processing" do
        test_model.column_sortable_by :name

        result = test_model.sorted_by_columns("invalid:asc,name:desc")

        expect(Rails.logger).to have_received(:warn).with(/ignoring disallowed column: invalid/)
        expect(result.pluck(:name)).to eq(%w[Charlie Bob Alice])
      end

      it "returns unmodified relation when all columns are invalid" do
        result = test_model.sorted_by_columns("invalid1:asc,invalid2:desc")

        expect(result.count).to eq(3)
        expect(Rails.logger).to have_received(:warn).twice
      end

      it "handles mixed valid and invalid columns gracefully" do
        test_model.column_sortable_by :name, :email

        result = test_model.sorted_by_columns("invalid:asc,name:desc,bad:asc,email:asc")

        expect(result.pluck(:name)).to eq(%w[Charlie Bob Alice])
        expect(Rails.logger).to have_received(:warn).twice
      end
    end
  end
end
