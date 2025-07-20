# frozen_string_literal: true

require "rails_helper"

RSpec.describe Saltbox::SortByColumns::Model, "Basic Functionality" do
  # Use the real User model from our Combustion app
  let(:test_model) { User }

  before do
    # Create test data
    @org_a = Organization.create!(name: "Alpha Corp")
    @org_b = Organization.create!(name: "Beta Inc")

    @user1 = User.create!(name: "Charlie", email: "charlie@example.com", organization: @org_b)
    @user2 = User.create!(name: "Alice", email: "alice@example.com", organization: @org_a)
    @user3 = User.create!(name: "Bob", email: "bob@example.com", organization: @org_a)
  end

  describe ".sort_by_columns" do
    it "stores allowed fields as symbols" do
      test_model.sort_by_columns :name, :email, :created_at
      expect(test_model.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "converts string inputs to symbols" do
      test_model.sort_by_columns "name", "email", "created_at"
      expect(test_model.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "handles mixed string and symbol inputs" do
      test_model.sort_by_columns :name, "email", :created_at
      expect(test_model.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "overwrites previous allowed fields" do
      test_model.sort_by_columns :name, :email
      test_model.sort_by_columns :email, :created_at
      expect(test_model.column_sortable_allowed_fields).to eq([:email, :created_at])
    end

    it "handles empty input" do
      test_model.sort_by_columns
      expect(test_model.column_sortable_allowed_fields).to eq([])
    end

    it "handles single column input" do
      test_model.sort_by_columns :name
      expect(test_model.column_sortable_allowed_fields).to eq([:name])
    end

    it "preserves order of columns" do
      test_model.sort_by_columns :email, :name, :created_at
      expect(test_model.column_sortable_allowed_fields).to eq([:email, :name, :created_at])
    end
  end

  describe ".column_sortable_allowed_fields" do
    it "returns empty array when none set" do
      # Reset any previous settings
      test_model.instance_variable_set(:@column_sortable_allowed_fields, nil)
      expect(test_model.column_sortable_allowed_fields).to eq([])
    end

    it "returns correct array of symbols after setting" do
      test_model.sort_by_columns :name, :email, :created_at
      expect(test_model.column_sortable_allowed_fields).to eq([:name, :email, :created_at])
    end

    it "returns cached value on subsequent calls" do
      test_model.sort_by_columns :name
      first_call = test_model.column_sortable_allowed_fields
      second_call = test_model.column_sortable_allowed_fields
      expect(first_call).to be(second_call) # Same object reference
    end
  end

  describe ".normalize_direction (private method)" do
    it "returns 'asc' for valid 'asc'" do
      result = test_model.send(:normalize_direction, "asc")
      expect(result).to eq("asc")
    end

    it "returns 'desc' for valid 'desc'" do
      result = test_model.send(:normalize_direction, "desc")
      expect(result).to eq("desc")
    end

    it "defaults to 'asc' for invalid values" do
      result = test_model.send(:normalize_direction, "invalid")
      expect(result).to eq("asc")
    end

    it "defaults to 'asc' for nil" do
      result = test_model.send(:normalize_direction, nil)
      expect(result).to eq("asc")
    end

    it "defaults to 'asc' for empty string" do
      result = test_model.send(:normalize_direction, "")
      expect(result).to eq("asc")
    end

    it "handles case sensitivity correctly (lowercase only)" do
      expect(test_model.send(:normalize_direction, "ASC")).to eq("asc")
      expect(test_model.send(:normalize_direction, "DESC")).to eq("asc") # Invalid, defaults to asc
      expect(test_model.send(:normalize_direction, "Asc")).to eq("asc")
      expect(test_model.send(:normalize_direction, "Desc")).to eq("asc") # Invalid, defaults to asc
    end

    it "handles numeric inputs" do
      result = test_model.send(:normalize_direction, 123)
      expect(result).to eq("asc")
    end
  end

  describe ".sorted_by_columns" do
    before do
      test_model.sort_by_columns :name, :email, :created_at, :organization__name
    end

    context "with nil or blank input" do
      it "returns all relation for nil" do
        result = test_model.sorted_by_columns(nil)
        expect(result.count).to eq(3)
        expect(result).to be_a(ActiveRecord::Relation)
      end

      it "returns all relation for empty string" do
        result = test_model.sorted_by_columns("")
        expect(result.count).to eq(3)
        expect(result).to be_a(ActiveRecord::Relation)
      end

      it "returns all relation for whitespace-only string" do
        result = test_model.sorted_by_columns("  \t\n  ")
        expect(result.count).to eq(3)
        expect(result).to be_a(ActiveRecord::Relation)
      end
    end

    context "with standard column sorting" do
      it "sorts by name ascending" do
        result = test_model.sorted_by_columns("name:asc").pluck(:name)
        expect(result).to eq(%w[Alice Bob Charlie])
      end

      it "sorts by name descending" do
        result = test_model.sorted_by_columns("name:desc").pluck(:name)
        expect(result).to eq(%w[Charlie Bob Alice])
      end

      it "sorts by email ascending" do
        result = test_model.sorted_by_columns("email:asc").pluck(:email)
        expect(result).to eq(%w[alice@example.com bob@example.com charlie@example.com])
      end

      it "sorts by email descending" do
        result = test_model.sorted_by_columns("email:desc").pluck(:email)
        expect(result).to eq(%w[charlie@example.com bob@example.com alice@example.com])
      end

      it "defaults to ascending when no direction specified" do
        result = test_model.sorted_by_columns("name").pluck(:name)
        expect(result).to eq(%w[Alice Bob Charlie])
      end
    end

    context "with multi-column sorting" do
      it "sorts by multiple columns" do
        # Create users with same name to test secondary sort
        User.create!(name: "Alice", email: "alice2@example.com", organization: @org_b)

        result = test_model.sorted_by_columns("name:asc,email:desc").pluck(:name, :email)
        alice_records = result.select { |name, email| name == "Alice" } # standard:disable Style/HashSlice

        # In descending email order: alice@example.com comes before alice2@example.com
        expect(alice_records.length).to eq(2)
        expect(alice_records.first[1]).to eq("alice@example.com")
        expect(alice_records.last[1]).to eq("alice2@example.com")
      end
    end

    context "with association column sorting" do
      it "sorts by organization name ascending" do
        result = test_model.sorted_by_columns("organization__name:asc").to_a
        expect(result.first.organization.name).to eq("Alpha Corp")
        expect(result.last.organization.name).to eq("Beta Inc")
      end

      it "sorts by organization name descending" do
        result = test_model.sorted_by_columns("organization__name:desc").to_a
        expect(result.first.organization.name).to eq("Beta Inc")
        expect(result.last.organization.name).to eq("Alpha Corp")
      end

      it "handles mixed association and regular column sorting" do
        result = test_model.sorted_by_columns("organization__name:asc,name:asc").to_a

        # First two should be from Alpha Corp, sorted by name
        expect(result[0].organization.name).to eq("Alpha Corp")
        expect(result[0].name).to eq("Alice")
        expect(result[1].organization.name).to eq("Alpha Corp")
        expect(result[1].name).to eq("Bob")

        # Last should be from Beta Corp
        expect(result[2].organization.name).to eq("Beta Inc")
        expect(result[2].name).to eq("Charlie")
      end
    end

    context "with custom scope columns (c_ prefix)" do
      before do
        test_model.sort_by_columns :name, :c_full_name
      end

      it "handles custom scope columns" do
        allow(test_model).to receive(:sorted_by_full_name).and_return(test_model.order(:name))

        result = test_model.sorted_by_columns("c_full_name:desc")

        expect(test_model).to have_received(:sorted_by_full_name).with("desc")
        expect(result).to be_a(ActiveRecord::Relation)
      end

      it "strips c_ prefix correctly" do
        allow(test_model).to receive(:sorted_by_full_name).and_return(test_model.order(:name))

        test_model.sorted_by_columns("c_full_name:asc")

        expect(test_model).to have_received(:sorted_by_full_name).with("asc")
      end

      it "defaults to asc direction for custom scopes" do
        allow(test_model).to receive(:sorted_by_full_name).and_return(test_model.order(:name))

        test_model.sorted_by_columns("c_full_name")

        expect(test_model).to have_received(:sorted_by_full_name).with("asc")
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
          test_model.send(:handle_error, error_message, column_name)
        }.to raise_error(ArgumentError, "Test error for column: invalid_column")
      end

      it "interpolates column name correctly" do
        expect {
          test_model.send(:handle_error, "Column %{column} is bad", "test_col")
        }.to raise_error(ArgumentError, "Column test_col is bad")
      end
    end

    context "in production environment" do
      before do
        allow(Rails.env).to receive(:local?).and_return(false)
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "logs warning instead of raising error" do
        result = test_model.send(:handle_error, error_message, column_name)

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring disallowed column: invalid_column")
        expect(result).to be_nil
      end

      it "logs warning with critical flag" do
        test_model.send(:handle_error, error_message, column_name, true)

        expect(Rails.logger).to have_received(:warn).with("SortByColumns ignoring all columns due to invalid_column")
      end

      it "handles nil Rails.logger gracefully" do
        allow(Rails).to receive(:logger).and_return(nil)

        expect {
          test_model.send(:handle_error, error_message, column_name)
        }.not_to raise_error
      end
    end
  end
end
