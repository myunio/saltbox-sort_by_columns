# frozen_string_literal: true

require_relative "sort_by_columns/version"
require_relative "sort_by_columns/model"
require_relative "sort_by_columns/controller"
require_relative "sort_by_columns/railtie" if defined?(Rails)

module Saltbox
  module SortByColumns
    # Main entry point for the Saltbox::SortByColumns gem
    #
    # This gem provides column-based sorting capabilities for Rails models
    # with support for associations and custom scopes.
    #
    # @example Basic usage in a model
    #   class User < ApplicationRecord
    #     include Saltbox::SortByColumns::Model
    #
    #     belongs_to :organization
    #
    #     column_sortable_by :name, :email, :created_at, :organization__name
    #   end
    #
    # @example Usage in a controller
    #   class UsersController < ApplicationController
    #     include Saltbox::SortByColumns::Controller
    #
    #     def index
    #       @users = apply_scopes(User).page(params[:page])
    #     end
    #   end
    #
    # @example API usage
    #   GET /users?sort=name:asc,email:desc
    #   GET /users?sort=organization__name:asc
    #   GET /users?sort=c_custom_sort:desc
  end
end

# Load shared examples for RSpec when available and properly initialized
if defined?(RSpec) && RSpec.respond_to?(:shared_examples)
  shared_examples_path = File.expand_path("../../spec/support/shared_examples.rb", __dir__)
  require shared_examples_path if File.exist?(shared_examples_path)
end
