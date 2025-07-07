# frozen_string_literal: true

RSpec.describe Saltbox::SortByColumns do
  it "has a version number" do
    expect(Saltbox::SortByColumns::VERSION).not_to be nil
  end

  it "defines the main module" do
    expect(Saltbox::SortByColumns).to be_a(Module)
  end

  it "defines the Model module" do
    expect(Saltbox::SortByColumns::Model).to be_a(Module)
  end

  it "defines the Controller module" do
    expect(Saltbox::SortByColumns::Controller).to be_a(Module)
  end
end
