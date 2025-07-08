require "rails_helper"

RSpec.describe "SortByColumns integration", type: :model do
  let!(:org_a) { Organization.create!(name: "Alpha Inc") }
  let!(:org_b) { Organization.create!(name: "Beta Corp") }

  let!(:user1) { User.create!(name: "Charlie", email: "charlie@example.com", organization: org_b) }
  let!(:user2) { User.create!(name: "Alice", email: "alice@example.com", organization: org_a) }
  let!(:user3) { User.create!(name: "Bob", email: "bob@example.com", organization: org_a) }

  context "standard column sorting" do
    it "sorts by name ascending" do
      result = User.sorted_by_columns("name:asc").pluck(:name)
      expect(result).to eq(%w[Alice Bob Charlie])
    end

    it "sorts by email descending" do
      result = User.sorted_by_columns("email:desc").pluck(:email)
      expect(result).to eq(%w[charlie@example.com bob@example.com alice@example.com])
    end
  end

  context "association column sorting" do
    it "sorts by organization name asc" do
      result = User.sorted_by_columns("organization__name:asc, name:asc").to_a
      expect(result.first.organization.name).to eq("Alpha Inc")
      expect(result.last.organization.name).to eq("Beta Corp")
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
  end

  context "invalid column handling in production" do
    it "ignores unknown columns and still sorts valid ones" do
      allow(Rails.env).to receive(:local?).and_return(false)
      result = User.sorted_by_columns("invalid:asc,name:desc")
      expect(result.first.name).to eq("Charlie")
    end
  end
end
