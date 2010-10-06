require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'

WINDOWS = Config::CONFIG['host_os'] =~ /msdos|mswin|win32|mingw|cygwin|/

desc "Clean the build files for the sys-admin source for UNIX systems"
task :clean do
  unless WINDOWS
    Dir.chdir('ext') do
      build_file = 'admin.' + Config::CONFIG['DLEXT']
      sh 'make distclean' if File.exists?(build_file)
      File.delete("sys/#{build_file}") if File.exists?("sys/#{build_file}")
    end
  end
end

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

if WINDOWS
  desc "Install the sys-admin library for MS Windows"
  task :install do
    install_dir = File.join(CONFIG['sitelibdir'], 'sys')
    Dir.mkdir(install_dir) unless File.exists?(install_dir)
    FileUtils.cp('lib/sys/admin.rb', install_dir, :verbose => true)
  end
else
  desc "Install the sys-admin library for Unix platforms"
  task :install => [:build] do
    Dir.chdir('ext') do
      sh 'make install'
    end
  end
end

desc "Run the test suite"
Rake::TestTask.new("test") do |t|
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
