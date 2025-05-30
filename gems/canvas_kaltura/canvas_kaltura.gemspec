# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "canvas_kaltura"
  spec.version       = "1.0.0"
  spec.authors       = ["Nick Cloward"]
  spec.email         = ["ncloward@instructure.com"]
  spec.summary       = "Canvas Kaltura"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "canvas_http"
  spec.add_dependency "canvas_slug"
  spec.add_dependency "canvas_sort"
  spec.add_dependency "legacy_multipart"
  spec.add_dependency "nokogiri"
end
