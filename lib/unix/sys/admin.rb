require 'sys/admin/custom'
require 'sys/admin/common'

# Code used as a fallback for UNIX platforms.

module Sys
  class Admin

    class PasswdStruct < FFI::Struct
      layout(
        :pw_name,   :string,
        :pw_passwd, :string,
        :pw_uid,    :uint,
        :pw_gid,    :uint,
        :pw_gecos,  :string,
        :pw_dir,    :string,
        :pw_shell,  :string
      )
    end

    class GroupStruct < FFI::Struct
      layout(
        :gr_name,   :string,
        :gr_passwd, :string,
        :gr_gid,    :uint,
        :gr_mem,    :pointer
      )
    end

    def self.get_login
      buf = FFI::MemoryPointer.new(:char, 256)

      if getlogin_r(buf, buf.size) != 0
        raise Error, "getlogin_r function failed: " + strerror(FFI.errno)
      end

      buf.read_string
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
        u.gecos  = pwd[:pw_gecos]
        u.dir    = pwd[:pw_dir]
        u.shell  = pwd[:pw_shell]
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
