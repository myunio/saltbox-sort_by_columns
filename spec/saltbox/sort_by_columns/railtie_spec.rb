# frozen_string_literal: true

require "spec_helper"

RSpec.describe Saltbox::SortByColumns::Railtie do
  describe "railtie configuration" do
    it "inherits from Rails::Railtie" do
      expect(Saltbox::SortByColumns::Railtie.superclass).to eq(Rails::Railtie)
    end

    it "sets the correct railtie name" do
      # Access the railtie name through the class
      expect(Saltbox::SortByColumns::Railtie.railtie_name).to eq("saltbox_sort_by_columns")
    end

    it "initializes configuration options" do
      # Check that the config object is set up
      expect(Rails.application.config).to respond_to(:saltbox_sort_by_columns)
    end

    it "creates an OrderedOptions configuration object" do
      config = Rails.application.config.saltbox_sort_by_columns
      expect(config).to be_an(ActiveSupport::OrderedOptions)
    end
  end

  describe "Rails integration" do
    it "loads only when Rails is defined" do
      # This is more of a documentation test since we're already in a Rails context
      # The actual conditional loading is tested in the main gem file
      expect(defined?(Rails)).to be_truthy
    end

    it "provides a namespace for future configuration" do
      # The railtie creates a configuration namespace that can be used like:
      # Rails.application.config.saltbox_sort_by_columns.some_setting = value
      config = Rails.application.config.saltbox_sort_by_columns

      # Should be able to set and retrieve configuration
      config.test_setting = "test_value"
      expect(config.test_setting).to eq("test_value")
    end

    it "maintains configuration isolation" do
      # Ensure that saltbox_sort_by_columns config doesn't interfere with other config
      config = Rails.application.config.saltbox_sort_by_columns
      main_config = Rails.application.config

      # Set a value on the saltbox config
      config.isolated_setting = "isolated"

      # The setting should exist on the saltbox config
      expect(config.isolated_setting).to eq("isolated")

      # The setting should not exist on the main config as an instance variable
      # (even though the mock responds to the method due to method_missing)
      expect(main_config.instance_variable_get(:@isolated_setting)).to be_nil

      # The configs should be different objects
      expect(config).not_to be(main_config)
    end
  end

  describe "railtie functionality" do
    it "is properly registered as a railtie" do
      # Check that the class is recognized as a railtie
      expect(Saltbox::SortByColumns::Railtie).to be < Rails::Railtie
    end

    it "provides configuration extension point" do
      # The railtie should allow for future configuration extensions
      # Test that we can extend the configuration
      config = Rails.application.config.saltbox_sort_by_columns
      config.future_feature = {enabled: true, options: []}

      expect(config.future_feature[:enabled]).to be true
      expect(config.future_feature[:options]).to eq([])
    end
  end

  describe "namespace verification" do
    it "creates the correct module hierarchy" do
      expect(Saltbox::SortByColumns::Railtie).to be_a(Class)
      expect(Saltbox::SortByColumns::Railtie.name).to eq("Saltbox::SortByColumns::Railtie")
    end

    it "is properly namespaced under Saltbox::SortByColumns" do
      expect(Saltbox::SortByColumns.constants).to include(:Railtie)
    end
  end

  describe "future extensibility" do
    it "allows for additional railtie configuration" do
      # This test ensures the railtie is set up in a way that allows
      # for future additions like initializers, generators, etc.

      # The config object should be extensible
      config = Rails.application.config.saltbox_sort_by_columns

      # Should be able to add nested configuration
      config.features = ActiveSupport::OrderedOptions.new
      config.features.sorting = true
      config.features.filtering = false

      expect(config.features.sorting).to be true
      expect(config.features.filtering).to be false
    end
  end
end
