# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'debug-bar/version'

Gem::Specification.new do |s|
  s.name        = 'wp-debug-bar'
  s.version     = DebugBar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Jeff Reinecke', 'Keith Stone']
  s.email       = ['jreinecke@whitepages.com', 'kstone@whitepages.com']
  s.homepage    = ''
  s.summary     = 'Whitepages Debug Bar'
  s.description = 'Whitepages standard debug bar'

  s.add_dependency 'awesome-print'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
