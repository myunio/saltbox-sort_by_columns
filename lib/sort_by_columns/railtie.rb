# frozen_string_literal: true

require "rails/railtie"

module SortByColumns
  class Railtie < Rails::Railtie
    railtie_name :sort_by_columns

    # Load shared examples for testing if RSpec is available
    initializer "sort_by_columns.load_shared_examples" do
      if defined?(RSpec)
        # Load shared examples in Rails test environment
        shared_examples_path = File.join(File.dirname(__FILE__), "..", "..", "spec", "support", "shared_examples.rb")
        require shared_examples_path if File.exist?(shared_examples_path)
      end
    end

    # Add any Rails-specific configuration here if needed in the future
    config.sort_by_columns = ActiveSupport::OrderedOptions.new
  end
end
