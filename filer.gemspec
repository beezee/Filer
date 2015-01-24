# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'filer/version'

Gem::Specification.new do |spec|
  spec.name          = "filing-cabinet"
  spec.version       = Filer::VERSION
  spec.authors       = ["Brian Zeligson"]
  spec.email         = ["brian.zeligson@gmail.com"]
  spec.summary       = %q{Indexes files and stores to s3}
  spec.description   = %q{Indexes files and stores to s3}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.5"
  spec.add_dependency "rake"
  spec.add_dependency "thor"
  spec.add_dependency "configliere"
  spec.add_dependency "notifier"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "flex"
  spec.add_dependency "flex-models"
  spec.add_dependency "fallen"
end
