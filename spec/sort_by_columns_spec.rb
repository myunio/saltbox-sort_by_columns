# frozen_string_literal: true

RSpec.describe SortByColumns do
  it "has a version number" do
    expect(SortByColumns::VERSION).not_to be nil
  end

  it "defines the main module" do
    expect(SortByColumns).to be_a(Module)
  end

  it "defines the Model module" do
    expect(SortByColumns::Model).to be_a(Module)
  end

  it "defines the Controller module" do
    expect(SortByColumns::Controller).to be_a(Module)
  end
end
