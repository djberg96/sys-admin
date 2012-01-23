require 'sys/admin/custom'
require 'sys/admin/common'

# The Darwin specific code.

module Sys
  class Admin
    attach_function :getlogin_r, [:pointer, :int], :int
    attach_function :getpwnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getpwuid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getgrnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getgrgid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int

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

    def self.get_user(uid)
      buf  = FFI::MemoryPointer.new(:char, 1024)
      pbuf = FFI::MemoryPointer.new(PasswdStruct)
      temp = PasswdStruct.new

      if uid.is_a?(String)
        if getpwnam_r(uid, temp, buf, buf.size, pbuf) != 0
          raise Error, "getpwnam_r function failed: " + strerror(FFI.errno)
        end
      else
        if getpwuid_r(uid, temp, buf, buf.size, pbuf) != 0
          raise Error, "getpwuid_r function failed: " + strerror(FFI.errno)
        end
      end

      ptr = pbuf.read_pointer

      if ptr.null?
        raise Error, "no user found for #{uid}"
      end

      pwd = PasswdStruct.new(ptr)
      get_user_from_struct(pwd)
    end

    def self.get_group(gid)
      buf  = FFI::MemoryPointer.new(:char, 1024)
      pbuf = FFI::MemoryPointer.new(PasswdStruct)
      temp = GroupStruct.new

      if gid.is_a?(String)
        if getgrnam_r(gid, temp, buf, buf.size, pbuf) != 0
          raise Error, "getgrnam_r function failed: " + strerror(FFI.errno)
        end
      else
        if getgrgid_r(gid, temp, buf, buf.size, pbuf) != 0
          raise Error, "getgrgid_r function failed: " + strerror(FFI.errno)
        end
      end

      ptr = pbuf.read_pointer

      if ptr.null?
        raise Error, "no group found for #{gid}"
      end

      grp = GroupStruct.new(ptr)
      get_group_from_struct(grp)
    end

    def self.users
      users = []

      begin
        setpwent()

        until (ptr = getpwent()).null?
          pwd = PasswdStruct.new(ptr)
          users << get_user_from_struct(pwd)
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
          groups << get_group_from_struct(grp)
        end
      ensure
        endgrent()
      end

      groups
    end

    private

    def self.get_group_from_struct(grp)
      Group.new do |g|
        g.name    = grp[:gr_name]
        g.passwd  = grp[:gr_passwd]
        g.gid     = grp[:gr_gid]
        g.members = grp[:gr_mem].read_array_of_string
      end
    end

    def self.get_user_from_struct(pwd)
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
  end
end
