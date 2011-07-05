require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'
include Config

WINDOWS = CONFIG['host_os'] =~ /msdos|mswin|win32|mingw|cygwin|windows/i

CLEAN.include(
  '**/*.gem',               # Gem files
  '**/*.rbc',               # Rubinius
  '**/*.o',                 # C object file
  '**/*.log',               # Ruby extension build log
  '**/Makefile',            # C Makefile
  '**/conftest.dSYM',       # OS X build directory
  "**/*.#{CONFIG['DLEXT']}" # C shared object
)

desc "Build the sys-admin library on UNIX systems (but don't install it)"
task :build => [:clean] do
  unless WINDOWS
    Dir.chdir('ext') do
      ruby 'extconf.rb'
      sh 'make'
      build_file = 'admin.' + Config::CONFIG['DLEXT']
      FileUtils.cp(build_file, 'sys')
    end
  end
end

namespace :gem do
  desc "Create a sys-admin gem file."
  task :create => [:clean] do
    spec = eval(IO.read('sys-admin.gemspec'))

    if WINDOWS
      spec.platform = Gem::Platform::CURRENT
      spec.platform.cpu = 'universal'
      spec.files = spec.files.reject{ |f| f.include?('ext') }
      spec.add_dependency('win32-security', '>= 0.1.2')
    else
      spec.files = spec.files.reject{ |f| f.include?('lib') }
      spec.extensions = ['ext/extconf.rb']
      spec.extra_rdoc_files << 'ext/sys/admin.c'
    end

    Gem::Builder.new(spec).build
  end

  desc "Install the sys-admin gem."
  task :install => [:create] do
    gem = Dir['*.gem'].first
    sh "gem install #{gem}"
  end
end

desc "Run the test suite"
Rake::TestTask.new('test') do |t|
  if WINDOWS
    t.libs << 'lib'
  else
    task :test => :build
    t.libs << 'ext'
    t.libs.delete('lib')
  end
  t.libs << 'test'
  t.test_files = FileList['test/test_sys_admin.rb']
end

task :test do
  Rake.application[:clean].execute
end

task :default => :test
