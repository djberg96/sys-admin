require 'sys/admin/custom'
require 'sys/admin/common'

# Code used as a fallback for UNIX platforms.

module Sys
  class Admin
    private

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

    public

    # Returns the login for the current process.
    #
    def self.get_login
      getlogin()
    end

    # Returns a User object for the given name or uid. Raises an error
    # if a user cannot be found.
    #
    # Examples:
    #
    #    Sys::Admin.get_user('joe')
    #    Sys::Admin.get_user(501)
    #
    def self.get_user(uid)
      if uid.is_a?(String)
        pwd = PasswdStruct.new(getpwnam(uid))
      else
        pwd = PasswdStruct.new(getpwuid(uid))
      end

      if pwd.null?
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

    # Returns a Group object for the given name or uid. Raises an error
    # if a group cannot be found.
    #
    # Examples:
    #
    #    Sys::Admin.get_group('admin')
    #    Sys::Admin.get_group(101)
    #
    def self.get_group(gid)
      if gid.is_a?(String)
        grp = GroupStruct.new(getgrnam(gid))
      else
        grp = GroupStruct.new(getgrgid(gid))
      end

      if grp.null?
        raise Error, "no group found for: #{gid}"
      end

      Group.new do |g|
        g.name    = grp[:gr_name]
        g.passwd  = grp[:gr_passwd]
        g.gid     = grp[:gr_gid]
        g.members = grp[:gr_mem].read_array_of_string
      end
    end

    # Returns an array of User objects for each user on the system.
    #
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

    # Returns an array of Group objects for each user on the system.
    #
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

    # Takes a GroupStruct and converts it to a Group object.
    def self.get_group_from_struct(grp)
      Group.new do |g|
        g.name    = grp[:gr_name]
        g.passwd  = grp[:gr_passwd]
        g.gid     = grp[:gr_gid]
        g.members = grp[:gr_mem].read_array_of_string
      end
    end

    # Takes a UserStruct and converts it to a User object.
    def self.get_user_from_struct(pwd)
      user = User.new do |u|
        u.name         = pwd[:pw_name]
        u.passwd       = pwd[:pw_passwd]
        u.uid          = pwd[:pw_uid]
        u.gid          = pwd[:pw_gid]
        u.gecos        = pwd[:pw_gecos]
        u.dir          = pwd[:pw_dir]
        u.shell        = pwd[:pw_shell]
      end

      user
    end
  end
end
