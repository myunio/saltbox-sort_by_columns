# frozen_string_literal: true

require "rails/railtie"

module Saltbox
  module SortByColumns
    class Railtie < Rails::Railtie
      railtie_name :saltbox_sort_by_columns

      # Add any Rails-specific configuration here if needed in the future
      config.saltbox_sort_by_columns = ActiveSupport::OrderedOptions.new
    end
  end
end
