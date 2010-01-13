require 'ffi'

module Sys
  class Admin
    extend FFI::Library

    class Error < StandardError; end

    class PasswdStruct < FFI::Struct
      members = [
        :pw_name,   :string,
        :pw_passwd, :string,
        :pw_uid,    :uint,
        :pw_gid,    :uint,
        :pw_change, :ulong,
        :pw_class,  :string,
        :pw_gecos,  :string,
        :pw_dir,    :string,
        :pw_shell,  :string,
        :pw_expire, :string,
        :pw_fields, :int
      ]

      layout(*members)
    end

    class User
      attr_accessor :name, :passwd, :uid, :gid, :change, :gecos
      attr_accessor :dir, :shell, :expire, :fields

      def initialize
        yield self if block_given?
      end
    end

    attach_function :getlogin, [], :string
    attach_function :getuid, [], :long
    attach_function :getpwnam, [:string], :pointer
    attach_function :getpwuid, [:long], :pointer

    attach_function :getlogin_r, [:string, :int], :string
    attach_function :getpwnam_r, [:string, :pointer, :pointer, :ulong, :pointer], :int
    attach_function :getpwuid_r, [:uint, :pointer, :string, :ulong, :pointer], :int

    class ::String
      def nstrip
        self[ /^[^\0]*/ ]
      end
    end
    
    def self.get_login
      buf = 1.chr * 256
      getlogin_r(buf, 256)
      buf.nstrip
    end

    def self.get_user(uid)
      if uid.is_a?(String)
        pwd = PasswdStruct.new(getpwnam(uid))
      else
        pwd = PasswdStruct.new(getpwuid(uid))
      end
      
      if pwd.nil?
        raise Error, "no user found for: #{uid}"
      end

      user = User.new do |u|
        u.name   = pwd[:pw_name]
        u.passwd = pwd[:pw_passwd]
        u.uid    = pwd[:pw_uid]
        u.gid    = pwd[:pw_gid]
        u.change = pwd[:pw_change]
        u.gecos  = pwd[:pw_gecos]
        u.dir    = pwd[:pw_dir]
        u.shell  = pwd[:pw_shell]
        u.expire = pwd[:pw_expire]
        u.fields = pwd[:pw_fields]
      end

      user
    end
  end
end
