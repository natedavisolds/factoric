# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'factoric/version'

Gem::Specification.new do |spec|
  spec.name          = "factoric"
  spec.version       = Factoric::VERSION
  spec.authors       = ["Nate Davis Olds"]
  spec.email         = ["nate@davisolds.com"]
  spec.summary       = %q{Know facts of information historically}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "inflections"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "guard-rspec"
end
