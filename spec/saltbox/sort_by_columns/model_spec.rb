# frozen_string_literal: true

require "spec_helper"

# Simple mock reflection class for testing
class MockReflection
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

# Mock ActiveRecord::Relation for testing
class MockRelation
  attr_reader :identifier

  def initialize(identifier)
    @identifier = identifier
  end

  def left_outer_joins(associations)
    MockRelation.new("#{identifier}_with_joins_#{associations}")
  end

  def reorder(sql)
    MockRelation.new("#{identifier}_ordered_by_#{sql}")
  end

  def ==(other)
    case other
    when String
      identifier == other
    when MockRelation
      identifier == other.identifier
    else
      false
    end
  end

  def to_s
    identifier
  end
end

RSpec.describe Saltbox::SortByColumns::Model do
  # Create a dummy class that includes the Model module for testing
  let(:dummy_class) do
    Class.new do
      include Saltbox::SortByColumns::Model

      def self.name
        "DummyModel"
      end

      def self.table_name
        "dummy_models"
      end

      def self.all
        MockRelation.new("all_relation")
      end

      def self.reflect_on_association(name)
        # Return nil by default (no associations exist)
        # Can be stubbed in individual tests
        case name
        when :organization, :department
          MockReflection.new(name)
        else
          nil
        end
      end

      def self.left_outer_joins(associations)
        MockRelation.new("joined_relation")
      end

      def self.reorder(sql)
        MockRelation.new("ordered_relation")
      end
    end
  end

  describe ".column_sortable_by" do
    it "stores allowed fields as symbols" do
      dummy_class.column_sortable_by :name, :email, :created_at

      expect(dummy_class.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "converts string inputs to symbols" do
      dummy_class.column_sortable_by "name", "email", "created_at"

      expect(dummy_class.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "handles mixed string and symbol inputs" do
      dummy_class.column_sortable_by :name, "email", :created_at

      expect(dummy_class.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "overwrites previous allowed fields" do
      dummy_class.column_sortable_by :name, :email
      dummy_class.column_sortable_by :status, :updated_at

      expect(dummy_class.column_sortable_allowed_fields).to eq([:status, :updated_at])
    end

    it "handles empty input" do
      dummy_class.column_sortable_by

      expect(dummy_class.column_sortable_allowed_fields).to eq([])
    end

    it "handles single column input" do
      dummy_class.column_sortable_by :name

      expect(dummy_class.column_sortable_allowed_fields).to eq([:name])
    end

    it "preserves order of columns" do
      dummy_class.column_sortable_by :z_last, :a_first, :m_middle

      expect(dummy_class.column_sortable_allowed_fields).to eq([:z_last, :a_first, :m_middle])
    end
  end

  describe ".column_sortable_allowed_fields" do
    it "returns empty array when none set" do
      # Reset any previous settings
      dummy_class.instance_variable_set(:@column_sortable_allowed_fields, nil)

      expect(dummy_class.column_sortable_allowed_fields).to eq([])
    end

    it "returns correct array of symbols after setting" do
      dummy_class.column_sortable_by :name, :email, :created_at

      expect(dummy_class.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "returns cached value on subsequent calls" do
      dummy_class.column_sortable_by :name
      first_call = dummy_class.column_sortable_allowed_fields
      second_call = dummy_class.column_sortable_allowed_fields

      expect(first_call).to be(second_call) # Same object reference
    end
  end

  describe ".normalize_direction (private method)" do
    it "returns 'asc' for valid 'asc'" do
      result = dummy_class.send(:normalize_direction, "asc")
      expect(result).to eq("asc")
    end

    it "returns 'desc' for valid 'desc'" do
      result = dummy_class.send(:normalize_direction, "desc")
      expect(result).to eq("desc")
    end

    it "defaults to 'asc' for invalid values" do
      result = dummy_class.send(:normalize_direction, "invalid")
      expect(result).to eq("asc")
    end

    it "defaults to 'asc' for nil" do
      result = dummy_class.send(:normalize_direction, nil)
      expect(result).to eq("asc")
    end

    it "defaults to 'asc' for empty string" do
      result = dummy_class.send(:normalize_direction, "")
      expect(result).to eq("asc")
    end

    it "handles case sensitivity correctly (lowercase only)" do
      expect(dummy_class.send(:normalize_direction, "ASC")).to eq("asc")
      expect(dummy_class.send(:normalize_direction, "DESC")).to eq("asc") # Invalid, defaults to asc
      expect(dummy_class.send(:normalize_direction, "Asc")).to eq("asc")
      expect(dummy_class.send(:normalize_direction, "Desc")).to eq("asc") # Invalid, defaults to asc
    end

    it "handles numeric inputs" do
      result = dummy_class.send(:normalize_direction, 123)
      expect(result).to eq("asc")
    end
  end

  describe ".sorted_by_columns" do
    before do
      dummy_class.column_sortable_by :name, :email, :created_at
    end

    context "with nil or blank input" do
      it "returns all relation for nil" do
        result = dummy_class.sorted_by_columns(nil)
        expect(result).to eq("all_relation")
      end

      it "returns all relation for empty string" do
        result = dummy_class.sorted_by_columns("")
        expect(result).to eq("all_relation")
      end

      it "returns all relation for whitespace-only string" do
        result = dummy_class.sorted_by_columns("  \t\n  ")
        expect(result).to eq("all_relation")
      end
    end

    context "with custom scope columns (c_ prefix)" do
      before do
        dummy_class.column_sortable_by :c_custom_sort, :name

        # Mock the custom scope method
        allow(dummy_class).to receive(:sorted_by_custom_sort).and_return("custom_sorted_relation")
      end

      it "handles custom scope columns" do
        result = dummy_class.sorted_by_columns("c_custom_sort:desc")

        expect(dummy_class).to have_received(:sorted_by_custom_sort).with("desc")
        expect(result).to eq("custom_sorted_relation")
      end

      it "strips c_ prefix correctly" do
        dummy_class.sorted_by_columns("c_custom_sort:asc")

        expect(dummy_class).to have_received(:sorted_by_custom_sort).with("asc")
      end

      it "defaults to asc direction for custom scopes" do
        dummy_class.sorted_by_columns("c_custom_sort")

        expect(dummy_class).to have_received(:sorted_by_custom_sort).with("asc")
      end
    end
  end

  describe ".handle_error (private method)" do
    let(:error_message) { "Test error for column: %{column}" }
    let(:column_name) { "invalid_column" }

    context "in development environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(true)
      end

      it "raises ArgumentError with interpolated message" do
        expect {
          dummy_class.send(:handle_error, error_message, column_name)
        }.to raise_error(ArgumentError, "Test error for column: invalid_column")
      end

      it "interpolates column name correctly" do
        expect {
          dummy_class.send(:handle_error, "Column %{column} is bad", "test_col")
        }.to raise_error(ArgumentError, "Column test_col is bad")
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warning instead of raising error" do
        result = dummy_class.send(:handle_error, error_message, column_name)

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: invalid_column")
        expect(result).to be_nil
      end

      it "logs warning with critical flag" do
        dummy_class.send(:handle_error, error_message, column_name, true)

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring all columns due to invalid_column")
      end

      it "handles nil Rails.logger gracefully" do
        allow(Rails).to receive(:logger).and_return(nil)

        expect {
          dummy_class.send(:handle_error, error_message, column_name)
        }.not_to raise_error
      end
    end
  end

  # ========================================================================
  # PHASE 2: EDGE CASES & INPUT VALIDATION
  # ========================================================================

  describe "Phase 2: Input Validation Edge Cases" do
    before do
      dummy_class.column_sortable_by :name, :email, :created_at
    end

    context "malformed column specifications" do
      it "handles columns with multiple colons" do
        allow(Rails.env).to receive(:local?).and_return(false)

        # "name:asc:extra" is parsed as column="name", direction="asc" (extra part ignored)
        result = dummy_class.sorted_by_columns("name:asc:extra")
        # Should process 'name' column successfully
        expect(result.identifier).to include("name ASC")
      end

      it "handles very long column names" do
        long_column_name = "a" * 1000
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        result = dummy_class.sorted_by_columns("#{long_column_name}:asc")
        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "handles columns with special characters" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        # SQL injection attempt or special characters
        result = dummy_class.sorted_by_columns("name'; DROP TABLE users; --:asc")
        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "handles columns with unicode characters" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        result = dummy_class.sorted_by_columns("naïme:asc")
        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "handles numeric column names" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        result = dummy_class.sorted_by_columns("123:asc")
        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "handles empty column names" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        result = dummy_class.sorted_by_columns(":asc")
        # Empty column is skipped silently, no warning logged, returns unmodified relation
        expect(result.identifier).to eq("all_relation")
      end

      it "handles multiple consecutive commas" do
        allow(Rails.env).to receive(:local?).and_return(false)

        # This should process valid columns and ignore empty ones
        result = dummy_class.sorted_by_columns("name:asc,,,email:desc")
        # Should process the valid columns despite the extra commas
        expect(result).not_to eq("all_relation")
      end

      it "handles trailing and leading commas" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns(",name:asc,email:desc,")
        # Should process the valid columns despite leading/trailing commas
        expect(result).not_to eq("all_relation")
      end

      it "handles whitespace in column specifications" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns(" name : asc , email : desc ")
        # Should handle whitespace gracefully now that we strip around colons
        expect(result.identifier).to include("name ASC")
        expect(result.identifier).to include("email DESC")
      end

      it "handles very long sort parameter strings" do
        allow(Rails.env).to receive(:local?).and_return(false)

        # Create a very long sort string with valid columns
        long_sort_string = (1..100).map { "name:asc" }.join(",")
        result = dummy_class.sorted_by_columns(long_sort_string)

        # Should handle long strings without crashing
        expect(result).not_to eq("all_relation")
      end
    end

    context "invalid direction specifications" do
      it "handles unknown directions gracefully" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns("name:unknown_direction")
        # Should default to 'asc' for unknown directions
        expect(result).not_to eq("all_relation")
      end

      it "handles directions with special characters" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns("name:asc'; DROP TABLE users; --")
        # Should default to 'asc' for invalid directions
        expect(result).not_to eq("all_relation")
      end

      it "handles numeric directions" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns("name:123")
        # Should default to 'asc' for numeric directions
        expect(result).not_to eq("all_relation")
      end

      it "handles boolean directions" do
        allow(Rails.env).to receive(:local?).and_return(false)

        result = dummy_class.sorted_by_columns("name:true")
        # Should default to 'asc' for boolean directions
        expect(result).not_to eq("all_relation")
      end
    end

    context "extreme input scenarios" do
      it "handles extremely large number of columns" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        # Create a sort string with many invalid columns
        many_columns = (1..500).map { |i| "invalid_col_#{i}:asc" }.join(",")
        result = dummy_class.sorted_by_columns(many_columns)

        expect(result).to eq("all_relation") # All invalid, should return unmodified
      end

      it "handles mixed valid and invalid columns in large batches" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        # Mix valid and invalid columns
        mixed_columns = ["name:asc"] + (1..100).map { |i| "invalid_#{i}:asc" } + ["email:desc"]
        result = dummy_class.sorted_by_columns(mixed_columns.join(","))

        # Should process the valid columns
        expect(result).not_to eq("all_relation")
      end

      it "handles nil embedded in string" do
        allow(Rails.env).to receive(:local?).and_return(false)

        # Test string with null bytes - Ruby actually processes this as "name" (null byte in middle)
        malicious_string = "name\u0000:asc"
        result = dummy_class.sorted_by_columns(malicious_string)

        # The column is processed as "name\u0000" which matches our allowed "name" column
        expect(result.identifier).to include("name ASC")
      end
    end
  end

  describe "Phase 2: Association Column Edge Cases" do
    before do
      dummy_class.column_sortable_by :name, :organization__name, :department__code
    end

    context "malformed association syntax" do
      it "handles association names with multiple underscores" do
        dummy_class.column_sortable_by :complex_association_name__column

        allow(dummy_class).to receive(:reflect_on_association).with(:complex_association_name).and_return(double("reflection"))

        result = dummy_class.sorted_by_columns("complex_association_name__column:asc")
        expect(result).not_to eq("all_relation")
      end

      it "handles missing column part after __" do
        allow(Rails.env).to receive(:local?).and_return(false)

        dummy_class.column_sortable_by :organization__
        result = dummy_class.sorted_by_columns("organization__:asc")

        # The gem processes this as association="organization", column="" (empty string)
        # This creates SQL like "organization. ASC NULLS LAST" which is technically valid
        expect(result.identifier).to include("organization.")
      end

      it "handles empty association name before __" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        dummy_class.column_sortable_by :__column_name
        result = dummy_class.sorted_by_columns("__column_name:asc")

        # Should handle gracefully
        expect(result).to eq("all_relation")
      end

      it "handles triple underscores" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        dummy_class.column_sortable_by :association___column
        result = dummy_class.sorted_by_columns("association___column:asc")

        # Should handle gracefully
        expect(result).to eq("all_relation")
      end

      it "handles association columns with special characters" do
        allow(Rails.env).to receive(:local?).and_return(false)

        dummy_class.column_sortable_by :"organization__name'; DROP TABLE"
        result = dummy_class.sorted_by_columns("organization__name'; DROP TABLE:asc")

        # The gem processes this (association exists in our mock), creating potentially dangerous SQL
        # but it does process it since the column is in allowed fields
        expect(result.identifier).to include("organization")
      end
    end

    context "non-existent associations" do
      it "handles non-existent associations in development" do
        allow(Rails.env).to receive(:local?).and_return(true)

        dummy_class.column_sortable_by :nonexistent__column

        expect {
          dummy_class.sorted_by_columns("nonexistent__column:asc")
        }.to raise_error(ArgumentError, /association 'nonexistent' doesn't exist/)
      end

      it "handles non-existent associations in production" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        dummy_class.column_sortable_by :nonexistent__column
        result = dummy_class.sorted_by_columns("nonexistent__column:asc")

        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "continues processing other columns when association is invalid" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        dummy_class.column_sortable_by :nonexistent__column, :name
        result = dummy_class.sorted_by_columns("nonexistent__column:asc,name:desc")

        # Should process the valid 'name' column despite invalid association
        expect(result).not_to eq("all_relation")
      end
    end

    context "valid associations with invalid columns" do
      it "handles valid association with potentially invalid column names" do
        allow(dummy_class).to receive(:reflect_on_association).with(:organization).and_return(double("reflection"))

        # Even with a weird column name, if the association exists, it should process
        dummy_class.column_sortable_by :organization__weird_column_name
        result = dummy_class.sorted_by_columns("organization__weird_column_name:asc")

        expect(result).not_to eq("all_relation")
      end
    end
  end

  describe "Phase 2: Custom Scope Edge Cases" do
    context "custom scope validation" do
      it "handles custom scopes with multiple columns in development" do
        allow(Rails.env).to receive(:local?).and_return(true)

        dummy_class.column_sortable_by :c_custom_sort, :name

        expect {
          dummy_class.sorted_by_columns("c_custom_sort:desc,name:asc")
        }.to raise_error(ArgumentError, /does not support multiple columns/)
      end

      it "handles custom scopes with multiple columns in production" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        dummy_class.column_sortable_by :c_custom_sort, :name
        result = dummy_class.sorted_by_columns("c_custom_sort:desc,name:asc")

        expect(Rails.logger).to have_received(:warn).with(/ignoring all columns due to/)
        expect(result).to eq("all_relation")
      end

      it "handles non-existent custom scope methods" do
        dummy_class.column_sortable_by :c_nonexistent_scope

        expect {
          dummy_class.sorted_by_columns("c_nonexistent_scope:asc")
        }.to raise_error(NoMethodError, /undefined method.*sorted_by_nonexistent_scope/)
      end

      it "handles custom scopes not in allowed fields in development" do
        allow(Rails.env).to receive(:local?).and_return(true)

        # Don't add c_not_allowed to allowed fields
        expect {
          dummy_class.sorted_by_columns("c_not_allowed:asc")
        }.to raise_error(ArgumentError, /disallowed sortable column/)
      end

      it "handles custom scopes not in allowed fields in production" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        result = dummy_class.sorted_by_columns("c_not_allowed:asc")

        expect(Rails.logger).to have_received(:warn)
        expect(result).to eq("all_relation")
      end

      it "handles malformed custom scope names" do
        allow(Rails.env).to receive(:local?).and_return(false)

        dummy_class.column_sortable_by :"c_'; DROP TABLE users; --"

        # This should fail when trying to call the malformed method name
        expect {
          dummy_class.sorted_by_columns("c_'; DROP TABLE users; --:asc")
        }.to raise_error(NoMethodError)
      end

      it "handles very short custom scope names" do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))

        # Custom scope with just 'c_' prefix and one character
        dummy_class.column_sortable_by :c_a

        # This should try to call sorted_by_a method
        expect {
          dummy_class.sorted_by_columns("c_a:asc")
        }.to raise_error(NoMethodError, /undefined method.*sorted_by_a/)
      end

      it "handles custom scope with no suffix after c_" do
        dummy_class.column_sortable_by :c_
        allow(Rails.env).to receive(:local?).and_return(false)

        # Edge case: "c_:" goes through custom scope path since it starts with "c_"
        # After stripping "c_" prefix, we get empty string, trying to call sorted_by_ method
        expect {
          dummy_class.sorted_by_columns("c_:asc")
        }.to raise_error(NoMethodError, /sorted_by_/)
      end
    end

    context "custom scope with whitespace and special formatting" do
      it "handles custom scope with extra whitespace" do
        dummy_class.column_sortable_by :c_test_scope
        allow(Rails.env).to receive(:local?).and_return(false)

        # " c_test_scope : desc " gets processed as column="c_test_scope", direction="desc"
        # after whitespace stripping, and since c_test_scope is in allowed fields, it processes as regular column
        result = dummy_class.sorted_by_columns(" c_test_scope : desc ")

        # Gets processed as a regular column, not a custom scope due to leading whitespace
        expect(result.identifier).to include("c_test_scope DESC")
      end
    end
  end
end
