# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# The default values come from either the defaults from modern values from graphql-ruby or from experimentation to not
# break canvas at the time this was written.
class GraphQLTuning
  # graphiql can't load the explorer if we go below 15, so we'll use that as long as our specs continue to pass
  def self.max_depth
    config["max_depth"] || 15
  end

  def self.max_complexity
    config["max_complexity"] || 375_000
  end

  def self.default_page_size
    config["default_page_size"] || 20
  end

  def self.default_max_page_size
    config["default_max_page_size"] || 100
  end

  def self.validate_max_errors
    config["validate_max_errors"] || 100
  end

  def self.max_query_string_tokens
    config["max_query_string_tokens"] || 5_000
  end

  def self.max_query_aliases
    config["max_query_aliases"] || 20
  end

  def self.max_query_directives
    config["max_query_directives"] || 5
  end

  def self.enable_deferred_graphql_tuning?
    !!config["enable_deferred_graphql_tuning"]
  end

  class << self
    private

    def config
      @config ||=
        YAML.safe_load(DynamicSettings.find(tree: :private)["canvas_graphql_tuning.yml", failsafe: nil] || "{}")
    end
  end
end
