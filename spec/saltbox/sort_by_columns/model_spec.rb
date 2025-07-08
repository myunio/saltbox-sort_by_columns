# frozen_string_literal: true

require "spec_helper"

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
        "all_relation"
      end

      def self.reflect_on_association(name)
        # Return nil by default (no associations exist)
        nil
      end

      def self.left_outer_joins(associations)
        "joined_relation"
      end

      def self.reorder(sql)
        "ordered_relation"
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
end
