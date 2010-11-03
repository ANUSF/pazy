Gem::Specification.new do |s|
  s.name        = 'pazy'
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Olaf Delgado-Friedrichs', 'ANUSF']
  s.email       = ['olaf.delgado-friedrichs@anu.edu.au']
  s.homepage    = 'http://sf.anu.edu.au/~oxd900'
  s.required_rubygems_version = '>= 1.3.5'
  s.add_development_dependency 'rspec'
  s.files        = Dir.glob('{lib,spec}/**/*') + %w(MIT-LICENSE)
  s.require_path = 'lib'

  s.summary     = 'Data structures for a more functional programming style.'
  s.description = %q{
  A collection of lazy and persistent data structures and mixin for
  Ruby that provide support for a more functional programming style.

  Lazy evaluation is a technique in which computations are deferred
  until their results are first used (which may be never). Pazy
  provides lazy (cached) attributes as well as an extension of the
  enumerable module that defers the execution of list manipulation
  methods until particular values are accessed.

  Persistent data structures are immutable data structures with shared
  information between instances. Any modification operation on such a
  structure will create a new instance while leaving the original one
  intact. This eliminates the need for manipulating data in place
  while at the same time avoiding the high cost of copying the
  complete structure.

  Portions of this code have been ported from the Clojure runtime
  system.
  }
end
