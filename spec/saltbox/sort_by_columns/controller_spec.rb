# frozen_string_literal: true

require "spec_helper"

# We need to mock has_scope before testing the controller module
unless defined?(HasScope)
  module HasScope
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_scope(scope_name, options = {})
        @has_scope_definitions ||= {}
        @has_scope_definitions[scope_name] = options
      end

      def has_scope_definitions
        @has_scope_definitions || {}
      end
    end
  end
end

RSpec.describe Saltbox::SortByColumns::Controller do
  # Create a dummy controller class that includes the Controller module
  let(:dummy_controller_class) do
    Class.new do
      include HasScope # Include has_scope first
      include Saltbox::SortByColumns::Controller

      def self.name
        "DummyController"
      end
    end
  end

  describe "module inclusion" do
    it "includes the module successfully" do
      expect(dummy_controller_class.included_modules).to include(Saltbox::SortByColumns::Controller)
    end

    it "extends the class with has_scope functionality" do
      expect(dummy_controller_class).to respond_to(:has_scope)
    end
  end

  describe "has_scope configuration" do
    it "defines has_scope for sorted_by_columns" do
      scope_definitions = dummy_controller_class.has_scope_definitions

      expect(scope_definitions).to have_key(:sorted_by_columns)
    end

    it "configures has_scope with correct parameter name" do
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      expect(sorted_by_columns_config[:as]).to eq(:sort)
    end

    it "restricts has_scope to index action only" do
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      expect(sorted_by_columns_config[:only]).to eq(:index)
    end

    it "configures all expected has_scope options" do
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      expect(sorted_by_columns_config).to include(
        as: :sort,
        only: :index
      )
    end
  end

  describe "dependency requirements" do
    it "requires has_scope gem to be available" do
      # This test verifies that has_scope is required for the module to work
      expect(defined?(HasScope)).to be_truthy
    end

    it "should raise an error if has_scope is not available" do
      # Create a new controller class without HasScope
      controller_without_has_scope = Class.new

      # This should raise an error when including the Controller module
      # because has_scope won't be available
      expect {
        controller_without_has_scope.class_eval do
          include Saltbox::SortByColumns::Controller
        end
      }.to raise_error(NoMethodError, /undefined method.*has_scope/)
    end
  end

  describe "integration behavior" do
    it "defines the correct scope method name" do
      # The controller should define has_scope for the :sorted_by_columns method
      # which corresponds to the scope defined in the Model module
      scope_definitions = dummy_controller_class.has_scope_definitions

      expect(scope_definitions.keys).to include(:sorted_by_columns)
    end

    it "uses the expected parameter name for URL parameters" do
      # When a request comes in with ?sort=name:asc, the has_scope should
      # map this to the sorted_by_columns scope on the model
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      expect(sorted_by_columns_config[:as]).to eq(:sort)
    end
  end

  describe "action restrictions" do
    it "only applies to index action" do
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      expect(sorted_by_columns_config[:only]).to eq(:index)
    end

    it "does not apply to other actions like show, create, update, destroy" do
      scope_definitions = dummy_controller_class.has_scope_definitions
      sorted_by_columns_config = scope_definitions[:sorted_by_columns]

      # Verify it's restricted to only :index
      expect(sorted_by_columns_config[:only]).to eq(:index)
      expect(sorted_by_columns_config[:only]).not_to be_an(Array)
    end
  end

  describe "module structure" do
    it "is defined as a concern" do
      expect(Saltbox::SortByColumns::Controller).to be_a(Module)
    end

    it "uses ActiveSupport::Concern pattern" do
      # Check if the module extends ActiveSupport::Concern
      # This gives it the `included` callback functionality
      expect(Saltbox::SortByColumns::Controller).to respond_to(:included)

      # Verify it has the included block that defines has_scope
      # We can test this by checking that including the module actually calls has_scope
      test_class = Class.new
      test_class.define_singleton_method(:has_scope) { |*args| }

      expect(test_class).to receive(:has_scope).with(:sorted_by_columns, as: :sort, only: :index)
      test_class.include(Saltbox::SortByColumns::Controller)
    end
  end
end
