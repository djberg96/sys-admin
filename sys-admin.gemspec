require 'rubygems'

spec = Gem::Specification.new do |gem|
   gem.name      = 'sys-admin'
   gem.version   = '1.5.2'
   gem.author    = 'Daniel J. Berger'
   gem.license   = 'Artistic 2.0'
   gem.email     = 'djberg96@gmail.com'
   gem.homepage  = 'http://www.rubyforge.org/projects/sysutils'
   gem.platform  = Gem::Platform::RUBY
   gem.summary   = 'A unified, cross platform replacement for the "etc" library.'
   gem.test_file = 'test/test_sys_admin.rb'
   gem.has_rdoc  = true

   gem.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST']
   gem.rubyforge_project = 'sysutils'
   gem.required_ruby_version = '>= 1.8.2'
	
   files = Dir["doc/*"] + Dir["examples/*"]
   files += Dir["test/*"] + Dir["[A-Z]*"]

   if Config::CONFIG['host_os'].match('mswin')
      files += Dir["lib/sys/admin.rb"]
      gem.platform = Gem::Platform::CURRENT
      gem.add_dependency('win32-security', '>= 0.1.2')
   else
      files += Dir["ext/**/*.{c,h}"]
      gem.extensions = ['ext/extconf.rb']
      gem.extra_rdoc_files << 'ext/sys/admin.c'
      gem.require_path = 'lib'
   end

   files.delete_if{ |item| item.include?('CVS') }

   gem.files = files
   
   gem.add_development_dependency('test-unit', '>= 2.0.3')

   gem.description = <<-EOF
      The sys-admin library is a unified, cross platform replacement for the
      'etc' library that ships as part of the Ruby standard library. It
      provides a common interface for all platforms, including MS Windows. In
      addition, it provides an interface for adding, deleting and configuring
      users on MS Windows.
   EOF
end

Gem::Builder.new(spec).build
