require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'rbconfig'

CLEAN.include("**/*.gem", "**/*.rbx", "**/*.rbc", "ruby.core", "**/*.lock")

namespace :gem do
  desc "Create the sys-uname gem"
  task :create => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('sys-admin.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc "Install the sys-uname gem"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

desc "Run the specs for the sys-admin library"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/sys_admin_unix_spec.rb'
  case RbConfig::CONFIG['host_os']
  when /darwin|osx/i
    t.rspec_opts = '-Ilib/darwin'
  when /linux/i
    t.rspec_opts = '-Ilib/linux'
  when /sunos|solaris/i
    t.rspec_opts = '-Ilib/sunos'
  when /bsd/i
    t.rspec_opts = '-Ilib/bsd'
  when /windows|win32|mingw|cygwin|dos/i
    t.rspec_opts = '-Ilib/windows'
    t.pattern = 'spec/sys_admin_unix_spec.rb'
  else
    t.rspec_opts = '-Ilib/unix'
  end
end

task :default => :test
