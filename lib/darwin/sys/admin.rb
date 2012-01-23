require 'sys/admin/custom'
require 'sys/admin/common'

# The Darwin specific code.

module Sys
  class Admin
    attach_function :getlogin_r, [:pointer, :int], :int

    # struct passwd from /usr/include/pwd.h
    class PasswdStruct < FFI::Struct
      layout(
        :pw_name, :string,
        :pw_passwd, :string,
        :pw_uid, :uint,
        :pw_gid, :uint,
        :pw_change, :ulong,
        :pw_class, :string,
        :pw_gecos, :string,
        :pw_dir, :string,
        :pw_shell, :string,
        :pw_expire, :ulong,
        :pw_fields, :int
      )
    end

    # struct group from /usr/include/grp.h
    class GroupStruct < FFI::Struct
      layout(
        :gr_name, :string,
        :gr_passwd, :string,
        :gr_gid, :uint,
        :gr_mem, :pointer
      )
    end

    def self.get_login
      buf = FFI::MemoryPointer.new(:char, 256)

      if getlogin_r(buf, buf.size) != 0
        raise Error, "getlogin_r function failed: " + strerror(FFI.errno)
      end

      buf.read_string
    end

    def self.get_user(uid_or_string)
      if uid_or_string.is_a?(String)
        ptr = getpwnam(uid_or_string)
      else
        ptr = getpwuid(uid_or_string)
      end

      raise Error, strerror(FFI.errno) if ptr.null?

      pwd = PasswdStruct.new(ptr)

      User.new do |u|
        u.name         = pwd[:pw_name]
        u.passwd       = pwd[:pw_passwd]
        u.uid          = pwd[:pw_uid]
        u.gid          = pwd[:pw_gid]
        u.change       = Time.at(pwd[:pw_change])
        u.access_class = pwd[:pw_class]
        u.gecos        = pwd[:pw_gecos]
        u.dir          = pwd[:pw_dir]
        u.shell        = pwd[:pw_shell]
        u.expire       = Time.at(pwd[:pw_expire])
        u.fields       = pwd[:pw_fields]
      end
    end

    def self.users
      users = []

      begin
        setpwent()

        until (ptr = getpwent()).null?
          pwd = PasswdStruct.new(ptr)
          users << User.new do |u|
            u.name         = pwd[:pw_name]
            u.passwd       = pwd[:pw_passwd]
            u.uid          = pwd[:pw_uid]
            u.gid          = pwd[:pw_gid]
            u.change       = Time.at(pwd[:pw_change])
            u.access_class = pwd[:pw_class]
            u.gecos        = pwd[:pw_gecos]
            u.dir          = pwd[:pw_dir]
            u.shell        = pwd[:pw_shell]
            u.expire       = Time.at(pwd[:pw_expire])
            u.fields       = pwd[:pw_fields]
          end
        end
      ensure
        endpwent()
      end

      users
    end

    def self.groups
      groups = []

      begin
        setgrent()

        until (ptr = getgrent()).null?
          grp = GroupStruct.new(ptr)
          groups << Group.new do |g|
            g.name    = grp[:gr_name]
            g.passwd  = grp[:gr_passwd]
            g.gid     = grp[:gr_gid]
            g.members = grp[:gr_mem].read_array_of_string
          end
        end
      ensure
        endgrent()
      end

      groups
    end
  end
end
