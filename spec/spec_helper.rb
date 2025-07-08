# frozen_string_literal: true

require "bundler/setup"

# Load ActiveSupport for blank? and other core extensions
require "active_support/core_ext/object/blank"
require "active_support/core_ext/string"
require "active_support/string_inquirer"
require "logger"

# Load ActiveRecord dependencies needed by the gem
require "active_record"
require "arel"

# Mock Rails environment for testing
unless defined?(Rails)
  # Create a mock Rails module with application support
  module Rails
    class << self
      def env
        @env ||= ActiveSupport::StringInquirer.new("test")
      end

      def logger
        @logger ||= Logger.new("/dev/null") # Null logger for tests
      end

      def application
        @application ||= MockApplication.new
      end
    end

    # Mock Rails application for Railtie testing
    class MockApplication
      def config
        @config ||= MockConfig.new
      end
    end

    # Mock configuration that supports dynamic method creation
    class MockConfig
      def initialize
        @saltbox_sort_by_columns = ActiveSupport::OrderedOptions.new
      end

      attr_reader :saltbox_sort_by_columns

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      def method_missing(method_name, *args, &block)
        if method_name.to_s.end_with?("=")
          instance_variable_set("@#{method_name.to_s.chomp("=")}", args.first)
        else
          instance_variable_get("@#{method_name}")
        end
      end
    end

    # Mock Railtie class for inheritance
    class Railtie
      def self.inherited(subclass)
        # Do nothing - just allow inheritance
      end

      def self.railtie_name(name = nil)
        if name
          @railtie_name = name.to_s
        else
          @railtie_name
        end
      end
    end
  end

  # Add local? method to Rails.env for our gem's environment detection
  Rails.env.define_singleton_method(:local?) { false }
end

require "saltbox-sort_by_columns"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Load shared examples
  Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }
end
