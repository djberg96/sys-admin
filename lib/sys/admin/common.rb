require 'ffi'

module Sys
  class Admin
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function :strerror, [:int], :string

    attach_function :getlogin, [], :string
    attach_function :getuid, [], :long
    attach_function :getpwnam, [:string], :pointer
    attach_function :getpwuid, [:long], :pointer
    attach_function :getpwent, [], :pointer
    attach_function :setpwent, [], :void
    attach_function :endpwent, [], :void

    attach_function :getgrgid, [:long], :pointer
    attach_function :getgrnam, [:string], :pointer
    attach_function :getgrent, [], :pointer
    attach_function :endgrent, [], :void
    attach_function :setgrent, [], :void

    VERSION = '1.6.0'

    class Error < StandardError; end

    class User
      attr_accessor :name, :passwd, :uid, :gid, :change, :gecos
      attr_accessor :dir, :shell, :expire, :fields, :access_class

      def initialize
        yield self if block_given?
      end
    end

    class Group
      attr_accessor :name
      attr_accessor :gid
      attr_accessor :members
      attr_accessor :passwd

      def initialize
        yield self if block_given?
      end
    end
  end
end
