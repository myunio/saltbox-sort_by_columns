require "rails_helper"

RSpec.describe "SortByColumns integration", type: :model do
  let!(:org_a) { Organization.create!(name: "Alpha Inc") }
  let!(:org_b) { Organization.create!(name: "Beta Corp") }

  let!(:user1) { User.create!(name: "Charlie", email: "charlie@example.com", organization: org_b) }
  let!(:user2) { User.create!(name: "Alice", email: "alice@example.com", organization: org_a) }
  let!(:user3) { User.create!(name: "Bob", email: "bob@example.com", organization: org_a) }

  before do
    User.column_sortable_by :name, :email, :organization__name, :c_full_name
  end

  context "standard column sorting" do
    it "sorts by name ascending" do
      result = User.sorted_by_columns("name:asc").pluck(:name)
      expect(result).to eq(%w[Alice Bob Charlie])
    end

    it "sorts by email descending" do
      result = User.sorted_by_columns("email:desc").pluck(:email)
      expect(result).to eq(%w[charlie@example.com bob@example.com alice@example.com])
    end

    it "handles multi-column sorting with real database" do
      # Create duplicate names to test secondary sort
      User.create!(name: "Alice", email: "alice2@example.com", organization: org_b)

      result = User.sorted_by_columns("name:asc,email:desc").pluck(:name, :email)
      alice_records = result.select { |name, email| name == "Alice" }

      expect(alice_records.length).to eq(2)
      # In descending email order: alice@example.com comes before alice2@example.com alphabetically
      expect(alice_records.first[1]).to eq("alice@example.com")
      expect(alice_records.last[1]).to eq("alice2@example.com")
    end
  end

  context "association column sorting" do
    it "sorts by organization name asc" do
      result = User.sorted_by_columns("organization__name:asc, name:asc").to_a
      expect(result.first.organization.name).to eq("Alpha Inc")
      expect(result.last.organization.name).to eq("Beta Corp")
    end

    it "generates correct SQL with LEFT OUTER JOIN" do
      result = User.sorted_by_columns("organization__name:asc")

      # Check that the query includes a LEFT OUTER JOIN
      expect(result.to_sql).to include("LEFT OUTER JOIN")
      expect(result.to_sql).to include("organizations")
      expect(result.to_sql).to include("ORDER BY")
    end

    it "handles NULL values in associations correctly" do
      # Create user without organization
      user_without_org = User.create!(name: "Orphan", email: "orphan@example.com", organization: nil)

      result = User.sorted_by_columns("organization__name:asc").to_a
      # Users without organizations should appear first (NULLS LAST for ASC)
      expect(result.last.name).to eq("Orphan")

      result_desc = User.sorted_by_columns("organization__name:desc").to_a
      # Users without organizations should appear last (NULLS FIRST for DESC)
      expect(result_desc.first.name).to eq("Orphan")
    end
  end

  context "custom scope column" do
    it "applies custom c_full_name scope" do
      # Add the custom column to allowed list for this example
      User.column_sortable_by :name, :c_full_name
      allow(User).to receive(:sorted_by_full_name).and_call_original

      result = User.sorted_by_columns("c_full_name:desc")
      expect(User).to have_received(:sorted_by_full_name).with("desc")
      expect(result.first.name).to eq("Charlie")
    end

    it "prevents mixing custom scopes with regular columns" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = User.sorted_by_columns("c_full_name:asc,name:desc")
      expect(result.count).to eq(3)
      # Should return unmodified relation when mixing custom scopes
      expect(result.pluck(:name)).to eq(%w[Charlie Alice Bob])
    end
  end

  context "edge cases with real Rails environment" do
    it "ignores unknown columns and still sorts valid ones" do
      allow(Rails.env).to receive(:local?).and_return(false)
      result = User.sorted_by_columns("invalid:asc,name:desc")
      expect(result.first.name).to eq("Charlie")
    end

    it "handles complex malformed input gracefully" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = User.sorted_by_columns("::invalid::,name:asc,,,bad_column:desc,")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles very long sort parameter strings" do
      allow(Rails.env).to receive(:local?).and_return(false)

      # Create a very long sort parameter with many invalid columns
      long_sort_param = (1..100).map { |i| "invalid_column_#{i}:asc" }.join(",") + ",name:desc"

      result = User.sorted_by_columns(long_sort_param)
      expect(result.pluck(:name)).to eq(%w[Charlie Bob Alice])
    end

    it "handles special characters in column names" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = User.sorted_by_columns("name@#$%:asc,email:desc")
      expect(result.pluck(:email)).to eq(%w[charlie@example.com bob@example.com alice@example.com])
    end

    it "handles association columns with invalid association names" do
      allow(Rails.env).to receive(:local?).and_return(false)

      User.column_sortable_by :name, :invalid_association__name

      result = User.sorted_by_columns("invalid_association__name:asc,name:desc")
      expect(result.pluck(:name)).to eq(%w[Charlie Bob Alice])
    end

    it "handles mixed valid and invalid columns efficiently" do
      allow(Rails.env).to receive(:local?).and_return(false)

      result = User.sorted_by_columns("invalid1:asc,name:desc,invalid2:asc,email:asc")

      # Should sort by name DESC first, then email ASC
      expect(result.pluck(:name)).to eq(%w[Charlie Bob Alice])
    end
  end

  context "performance with edge cases" do
    it "processes large allowed fields list efficiently" do
      # Create a large list of allowed fields
      large_fields = [:name, :email] + (1..100).map { |i| :"field_#{i}" }
      User.column_sortable_by(*large_fields)

      result = User.sorted_by_columns("name:asc")
      expect(result.pluck(:name)).to eq(%w[Alice Bob Charlie])
    end

    it "handles repeated calls efficiently" do
      # Test that repeated calls don't cause memory leaks or performance issues
      100.times do
        result = User.sorted_by_columns("name:asc")
        expect(result.count).to eq(3)
      end
    end
  end

  context "development environment error handling" do
    before { allow(Rails.env).to receive(:local?).and_return(true) }

    it "raises helpful errors for invalid columns" do
      expect {
        User.sorted_by_columns("invalid_column:asc")
      }.to raise_error(ArgumentError, /disallowed sortable column/)
    end

    it "raises helpful errors for invalid associations" do
      User.column_sortable_by :name, :invalid_association__name

      expect {
        User.sorted_by_columns("invalid_association__name:asc")
      }.to raise_error(ArgumentError, /doesn't exist on model/)
    end

    it "raises helpful errors for mixed custom scope columns" do
      expect {
        User.sorted_by_columns("c_full_name:asc,c_another_scope:desc")
      }.to raise_error(ArgumentError, /does not support multiple columns/)
    end
  end
end
