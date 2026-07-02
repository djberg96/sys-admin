# frozen_string_literal: true

# The Sys modules serves as a namespace only.
module Sys
  # The Admin class provides a unified, cross platform replacement for the Etc module.
  class Admin
    # The version of the sys-admin library.
    VERSION = '1.9.0'

    private_class_method :new
  end
end

# Stub to require the correct based on platform
require 'rbconfig'

case RbConfig::CONFIG['host_os']
  when /linux/i
    require_relative '../linux/sys/admin'
  when /sunos|solaris/i
    require_relative '../sunos/sys/admin'
  when /cygwin|mingw|mswin|windows|dos/i
    require_relative '../windows/sys/admin'
  when /darwin|mach/i
    require_relative '../darwin/sys/admin'
  when /bsd|dragonfly/i
    require_relative '../bsd/sys/admin'
  else
    require_relative '../unix/sys/admin'
end
