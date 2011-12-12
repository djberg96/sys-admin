require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'

CLEAN.include("**/*.gem", "**/*.rbx", "**/*.rbc")

Rake::TestTask.new('test') do |t|
  case RbConfig::CONFIG['host_os']
  when /darwin|osx/i
    t.libs << 'lib/darwin'
  when /linux/i
    t.libs << 'lib/linux'
  when /sunos|solaris/i
    t.libs << 'lib/sunos'
  end

  t.warning = true
  t.verbose = true

  t.libs << 'test'
  t.test_files = FileList['test/test_sys_admin.rb']
end

task :default => :test
