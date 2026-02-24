# frozen_string_literal: true

require "pagy/extras/headers"
require "pagy/extras/metadata"

Pagy::DEFAULT[:items] = ENV.fetch("DEFAULT_PAGE_SIZE", 20).to_i
Pagy::DEFAULT[:max_pages] = 1_000
