# frozen_string_literal: true

require 'sys/admin/custom'
require 'sys/admin/common'

# The Solaris specific code.

# The Sys module serves as a namespace only.
module Sys
  # The Admin class provides a unified, cross platform replacement for the Etc module.
  class Admin
    # :no-doc:
    BUF_MAX = 65536 # Max buffer size for retry.
    private_constant :BUF_MAX

    # I'm making some aliases here to prevent potential conflicts
    attach_function :open_c, :open, %i[string int], :int
    attach_function :pread_c, :pread, %i[int pointer size_t off_t], :size_t
    attach_function :close_c, :close, [:int], :int

    attach_function :getlogin_r, %i[pointer size_t], :pointer
    attach_function :getpwnam_r, %i[string pointer pointer size_t], :pointer
    attach_function :getpwuid_r, %i[long pointer pointer size_t], :pointer
    attach_function :getpwent_r, %i[pointer pointer int], :pointer
    attach_function :getgrent_r, %i[pointer pointer int], :pointer
    attach_function :getgrnam_r, %i[string pointer pointer int], :pointer
    attach_function :getgrgid_r, %i[long pointer pointer int], :pointer

    private_class_method :getlogin_r, :getpwnam_r, :getpwuid_r, :getpwent_r
    private_class_method :getgrent_r, :getgrnam_r, :getgrgid_r
    private_class_method :open_c, :pread_c, :close_c

    # struct passwd from /usr/include/pwd.h
    class PasswdStruct < FFI::Struct
      layout(
        :pw_name, :string,
        :pw_passwd, :string,
        :pw_uid, :uint,
        :pw_gid, :uint,
        :pw_age, :string,
        :pw_comment, :string,
        :pw_gecos, :string,
        :pw_dir, :string,
        :pw_shell, :string
      )
    end

    private_constant :PasswdStruct

    # struct group from /usr/include/grp.h
    class GroupStruct < FFI::Struct
      layout(
        :gr_name, :string,
        :gr_passwd, :string,
        :gr_gid, :uint,
        :gr_mem, :pointer
      )
    end

    private_constant :GroupStruct

    # I'm blending the timeval struct in directly here
    class LastlogStruct < FFI::Struct
      layout(
        :ll_time, :uint,
        :ll_line, [:char, 32],
        :ll_host, [:char, 256]
      )
    end

    private_constant :LastlogStruct

    # Returns the login for the current process.
    #
    def self.get_login
      buf = FFI::MemoryPointer.new(:char, 256)

      ptr = getlogin_r(buf, buf.size)

      if ptr.null?
        raise Error, "getlogin_r function failed: #{strerror(FFI.errno)}"
      end

      buf.read_string
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
      buf  = FFI::MemoryPointer.new(:char, 1024)
      temp = PasswdStruct.new

      if uid.is_a?(String)
        ptr = getpwnam_r(uid, temp, buf, buf.size)
      else
        ptr = getpwuid_r(uid, temp, buf, buf.size)
      end

      if ptr.null?
        raise Error, "getpwnam_r or getpwuid_r function failed: #{strerror(FFI.errno)}"
      end

      pwd = PasswdStruct.new(ptr)
      get_user_from_struct(pwd)
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
      size = 1024
      buf  = FFI::MemoryPointer.new(:char, size)
      temp = GroupStruct.new

      begin
        if gid.is_a?(String)
          ptr = getgrnam_r(gid, temp, buf, buf.size)
          fun = 'getgrnam_r'
        else
          ptr = getgrgid_r(gid, temp, buf, buf.size)
          fun = 'getgrgid_r'
        end

        # SunOS distinguishes between a failed function call and a
        # group that isn't found.

        if ptr.null?
          if FFI.errno > 0
            raise SystemCallError.new(fun, FFI.errno)
          else
            raise Error, "group '#{gid}' not found"
          end
        end
      rescue Errno::ERANGE
        size += 1024
        raise if size > BUF_MAX
        buf = FFI::MemoryPointer.new(:char, size)
        retry
      end

      grp = GroupStruct.new(ptr)
      get_group_from_struct(grp)
    end

    # Returns an array of User objects for each user on the system.
    #
    def self.users
      users = []

      buf  = FFI::MemoryPointer.new(:char, 1024)
      temp = PasswdStruct.new

      begin
        setpwent()

        while !(ptr = getpwent_r(temp, buf, buf.size)).null?
          break if ptr.null?

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

      buf  = FFI::MemoryPointer.new(:char, 1024)
      temp = GroupStruct.new

      begin
        setgrent()

        while !(ptr = getgrent_r(temp, buf, buf.size)).null?
          break if ptr.null?

          grp = GroupStruct.new(ptr)
          groups << get_group_from_struct(grp)
        end
      ensure
        endgrent()
      end

      groups
    end

    # Takes a GroupStruct and converts it to a Group object.
    def self.get_group_from_struct(grp)
      Group.new do |g|
        g.name    = grp[:gr_name]
        g.passwd  = grp[:gr_passwd]
        g.gid     = grp[:gr_gid]
        g.members = grp[:gr_mem].read_array_of_string
      end
    end

    private_class_method :get_group_from_struct

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

      log = get_lastlog_info(user.uid)

      if log
        login_device = log[:ll_line].to_s
        login_host   = log[:ll_host].to_s

        user.login_time   = Time.at(log[:ll_time]) if log[:ll_time] > 0
        user.login_device = login_device unless login_device.empty?
        user.login_host   = login_host unless login_host.empty?
      end

      user
    end

    private_class_method :get_use_from_struct

    # The use of pread was necessary here because it's a sparse file. Note
    # also that while Solaris supports the getuserattr function, it doesn't
    # appear to store anything regarding login information.
    #
    def self.get_lastlog_info(uid)
      logfile = '/var/adm/lastlog'
      lastlog = LastlogStruct.new

      begin
        fd = open_c(logfile, File::RDONLY)

        if fd != -1
          bytes = pread_c(fd, lastlog, lastlog.size, uid * lastlog.size)
          if bytes < 0
            raise Error, "pread function failed: #{strerror(FFI.errno)}"
          end
        else
          nil # Ignore, improper permissions
        end
      ensure
        close_c(fd) if fd && fd >= 0
      end

      lastlog
    end

    private_class_method :get_lastlog_info
  end
end
