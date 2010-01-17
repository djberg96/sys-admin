require 'ffi'

module Sys
  class Admin
    extend FFI::Library

    class Error < StandardError; end

    class FFI::Pointer
      # Read an array of null separated strings.
      def read_string_array
        elements = []
        psz = self.class.size
        loc = self

        until (element = loc.read_pointer).null?
          elements << element.read_string_to_null
          loc += psz
        end

        elements
      end
    end

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

    class GroupStruct < FFI::Struct
      members = [
        :gr_name,   :string,
        :gr_passwd, :string,
        :gr_gid,    :uint,
        :gr_mem,    :pointer
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

    class Group
      attr_accessor :name
      attr_accessor :gid
      attr_accessor :members
      attr_accessor :passwd

      def initialize
        yield self if block_given?
      end
    end

    attach_function :getlogin, [], :string
    attach_function :getuid, [], :long
    attach_function :getpwnam, [:string], :pointer
    attach_function :getpwuid, [:long], :pointer
    attach_function :getgrgid, [:long], :pointer
    attach_function :getgrnam, [:string], :pointer
    attach_function :getgrent, [], :pointer
    attach_function :endgrent, [], :void
    attach_function :setgrent, [], :void

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

    def self.groups
      groups = []

      begin
        setgrent()
        until (grp_ptr = getgrent()).null?
          grp = GroupStruct.new(grp_ptr)
          groups << Group.new do |g|
            g.name    = grp[:gr_name]
            g.passwd  = grp[:gr_passwd]
            g.gid     = grp[:gr_gid]
            g.members = grp[:gr_mem].read_string_array
          end
        end
      ensure
        endgrent()
      end

      groups
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

    def self.get_group(gid)
      if gid.is_a?(String)
        grp = GroupStruct.new(getgrnam(gid))
      else
        grp = GroupStruct.new(getgrgid(gid))
      end

      if grp.nil?
        raise Error, "no group found for: #{gid}"
      end

      group = Group.new do |g|
        g.name    = grp[:gr_name]
        g.passwd  = grp[:gr_passwd]
        g.gid     = grp[:gr_gid]
        g.members = grp[:gr_mem].read_string_array
      end
    end
  end
end
