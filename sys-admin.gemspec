# Do not use this file directly. Build the gem via the Rake tasks.
require 'rubygems'

Gem::Specification.new do |spec|
  spec.name      = 'sys-admin'
  spec.version   = '1.6.3'
  spec.author    = 'Daniel J. Berger'
  spec.license   = 'Artistic 2.0'
  spec.email     = 'djberg96@gmail.com'
  spec.homepage  = 'http://www.github.com/djberg96/sysutils'
  spec.summary   = 'A unified, cross platform replacement for the "etc" library.'
  spec.test_file = 'test/test_sys_admin.rb'
  spec.files     = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST']
  spec.rubyforge_project = 'sysutils'
	
  spec.add_dependency('ffi', '>= 1.1.0')

  spec.add_development_dependency('test-unit', '>= 2.5.0')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The sys-admin library is a unified, cross platform replacement for the
    'etc' library that ships as part of the Ruby standard library. It
    provides a common interface for all platforms, including MS Windows. In
    addition, it provides an interface for adding, deleting and configuring
    users on MS Windows.
  EOF
end
