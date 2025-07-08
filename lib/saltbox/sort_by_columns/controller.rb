# frozen_string_literal: true

require "active_support/concern"

# Note: This module requires the use of the has_scope gem.
# https://github.com/heartcombo/has_scope

# In your controller ensure you call `apply_scopes` on the model scope
# somewhere or the params won't be processed.

module Saltbox
  module SortByColumns
    module Controller
      extend ActiveSupport::Concern

      included do
        has_scope :sorted_by_columns, # the model scope
          as: :sort, # the param name
          only: :index
      end
    end
  end
end
