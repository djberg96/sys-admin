require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rbconfig'

CLEAN.include("**/*.gem", "**/*.rbx", "**/*.rbc", "ruby.core")

namespace :gem do
  desc "Create the sys-uname gem"
  task :create => [:clean] do
    require 'rubygems/package'
    spec = eval(IO.read('sys-admin.gemspec'))
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc "Install the sys-uname gem"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

Rake::TestTask.new('test') do |t|
  case RbConfig::CONFIG['host_os']
  when /darwin|osx/i
    t.libs << 'lib/darwin'
  when /linux/i
    t.libs << 'lib/linux'
  when /sunos|solaris/i
    t.libs << 'lib/sunos'
  when /bsd/i
    t.libs << 'lib/bsd'
  when /windows|win32|mingw|cygwin|dos/i
    t.libs << 'lib/windows'
  else
    t.libs << 'lib/unix'
  end

  t.warning = true
  t.verbose = true

  t.libs << 'test'
  t.test_files = FileList['test/test_sys_admin.rb']
end

task :default => :test
