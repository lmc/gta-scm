# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gta_scm/version'

Gem::Specification.new do |spec|
  spec.name          = "gta-scm"
  spec.version       = GtaScm::VERSION
  spec.authors       = ["Luke Mcildoon"]
  spec.email         = ["luke@twofiftyfive.net"]

  spec.summary       = %q{Assembler, debugger and decompiler for the GTA3/Vice City/San Andreas script virtual machine.}
  spec.description   = %q{Assembler, debugger and decompiler for the GTA3/Vice City/San Andreas script virtual machine.}
  spec.homepage      = "https://github.com/lmc/gta-scm"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'activesupport'
  spec.add_dependency 'andand'
  spec.add_dependency 'binary_search'
  spec.add_dependency 'elparser'
  spec.add_dependency 'parallel'
  spec.add_dependency 'parser'
  spec.add_dependency "progress_bar"

  spec.add_dependency "ragweed"
  spec.add_dependency "iconv"

  spec.add_dependency "rutui"

end
