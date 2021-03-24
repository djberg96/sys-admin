module Sys
  class Admin
    # The version of the sys-admin library.
    VERSION = '1.7.6'.freeze
  end
end

# Stub to require the correct based on platform
require 'rbconfig'

case RbConfig::CONFIG['host_os']
  when /linux/i
    require 'linux/sys/admin'
  when /sunos|solaris/i
    require 'sunos/sys/admin'
  when /cygwin|mingw|mswin|windows|dos/i
    require 'windows/sys/admin'
  when /darwin|mach/i
    require 'darwin/sys/admin'
  when /bsd/i
    require 'bsd/sys/admin'
  else
    require 'unix/sys/admin'
end
