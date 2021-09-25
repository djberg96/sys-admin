# Do not use this file directly. Build the gem via the Rake tasks.
require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'sys-admin'
  spec.version    = '1.8.1'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Apache-2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://www.github.com/djberg96/sys-admin'
  spec.summary    = 'A unified, cross platform replacement for the "etc" library.'
  spec.test_files = Dir['spec/*.rb']
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.extra_rdoc_files = Dir['*.rdoc']
	
  spec.add_dependency('ffi', '~> 1.1')

  if Gem.win_platform?
    spec.platform = Gem::Platform.new(['universal', 'mingw32'])
    spec.add_dependency('win32-security', '~> 0.5')
  end

  spec.add_development_dependency('rspec', '~> 3.9')
  spec.add_development_dependency('rake')

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/sys-admin',
    'bug_tracker_uri'   => 'https://github.com/djberg96/sys-admin/issues',
    'changelog_uri'     => 'https://github.com/djberg96/sys-admin/blob/main/CHANGES.md',
    'documentation_uri' => 'https://github.com/djberg96/sys-admin/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/sys-admin',
    'wiki_uri'          => 'https://github.com/djberg96/sys-admin/wiki'
  }

  spec.description = <<-EOF
    The sys-admin library is a unified, cross platform replacement for the
    'etc' library that ships as part of the Ruby standard library. It
    provides a common interface for all platforms, including MS Windows. In
    addition, it provides an interface for adding, deleting and configuring
    users on MS Windows.
  EOF
end
