# frozen_string_literal: true

require_relative '../../sys/admin/custom'
require_relative '../../sys/admin/common'
require 'rbconfig'

# The BSD specific code.

# The Sys module serves as a namespace only.
module Sys
  # The Admin class provides a unified, cross platform replacement for the Etc module.
  class Admin
    # :no-doc:
    BUF_MAX = 65536 # Max buffer for retry
    private_constant :BUF_MAX

    FREEBSD_UTX = RbConfig::CONFIG['host_os'].match?(/freebsd/i)
    UTXDB_LASTLOGIN = 1

    private_constant :FREEBSD_UTX
    private_constant :UTXDB_LASTLOGIN

    # I'm making some aliases here to prevent potential conflicts
    attach_function :open_c, :open, %i[string int], :int
    attach_function :pread_c, :pread, %i[int pointer size_t off_t], :ssize_t
    attach_function :close_c, :close, [:int], :int

    attach_function :getlogin_r, %i[pointer int], :int
    attach_function :getpwnam_r, %i[string pointer pointer size_t pointer], :int
    attach_function :getpwuid_r, %i[long pointer pointer size_t pointer], :int
    attach_function :getgrnam_r, %i[string pointer pointer size_t pointer], :int
    attach_function :getgrgid_r, %i[long pointer pointer size_t pointer], :int

    if FREEBSD_UTX
      attach_function :setutxdb, %i[int pointer], :int
      attach_function :getutxuser, [:string], :pointer
      attach_function :endutxent, [], :void

      private_class_method :setutxdb, :getutxuser, :endutxent
    end

    private_class_method :getlogin_r, :getpwnam_r, :getpwuid_r, :getgrnam_r, :getgrgid_r
    private_class_method :open_c, :pread_c, :close_c

    # struct passwd from /usr/include/pwd.h
    class PasswdStruct < FFI::Struct
      fields = %i[
        pw_name string
        pw_passwd string
        pw_uid uid_t
        pw_gid gid_t
        pw_change time_t
        pw_class string
        pw_gecos string
        pw_dir string
        pw_shell string
        pw_expire time_t
      ]

      if RbConfig::CONFIG['host_os'] =~ /freebsd|dragonfly/i
        fields.push(:pw_fields, :int)
      end

      layout(*fields)
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
        :ll_time, :int32,
        :ll_line, [:char, 32],
        :ll_host, [:char, 256]
      )
    end

    private_constant :LastlogStruct

    if FREEBSD_UTX
      # struct utmpx from /usr/include/utmpx.h
      class UtmpxStruct < FFI::Struct
        layout(
          :ut_type, :short,
          :tv_sec, :time_t,
          :tv_usec, :suseconds_t,
          :ut_id, [:char, 8],
          :ut_pid, :pid_t,
          :ut_user, [:char, 32],
          :ut_line, [:char, 16],
          :ut_host, [:char, 128],
          :ut_spare, [:char, 64]
        )
      end

      private_constant :UtmpxStruct
    end

    # Returns the login for the current process.
    #
    def self.get_login
      buf = FFI::MemoryPointer.new(:char, 256)
      val = getlogin_r(buf, buf.size)

      if val != 0
        return get_user(geteuid()).name
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
      if uid.is_a?(String)
        ptr = lookup_user('getpwnam_r', uid) { |temp, buf, pbuf| getpwnam_r(uid, temp, buf, buf.size, pbuf) }
      else
        ptr = lookup_user('getpwuid_r', uid) { |temp, buf, pbuf| getpwuid_r(uid, temp, buf, buf.size, pbuf) }
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
      if gid.is_a?(String)
        ptr = lookup_group('getgrnam_r', gid) { |temp, buf, pbuf| getgrnam_r(gid, temp, buf, buf.size, pbuf) }
      else
        ptr = lookup_group('getgrgid_r', gid) { |temp, buf, pbuf| getgrgid_r(gid, temp, buf, buf.size, pbuf) }
      end

      grp = GroupStruct.new(ptr)
      get_group_from_struct(grp)
    end

    # Looks up a user with a retryable buffer for NSS-backed records.
    def self.lookup_user(fun, id)
      size = 1024
      buf  = FFI::MemoryPointer.new(:char, size)
      pbuf = FFI::MemoryPointer.new(:pointer)
      temp = PasswdStruct.new

      begin
        pbuf.write_pointer(FFI::Pointer::NULL)
        val = yield temp, buf, pbuf
        ptr = pbuf.read_pointer

        raise Error, "no user found for #{id}" if val == 0 && ptr.null?
        raise Error, "no user found for #{id}" if val == Errno::ENOENT::Errno
        raise SystemCallError.new(fun, val) if val != 0

        ptr
      rescue Errno::ERANGE
        size += 1024
        raise if size > BUF_MAX
        buf = FFI::MemoryPointer.new(:char, size)
        retry
      end
    end

    private_class_method :lookup_user

    # Looks up a group with a retryable buffer for large member lists.
    def self.lookup_group(fun, id)
      size = 1024
      buf  = FFI::MemoryPointer.new(:char, size)
      pbuf = FFI::MemoryPointer.new(:pointer)
      temp = GroupStruct.new

      begin
        pbuf.write_pointer(FFI::Pointer::NULL)
        val = yield temp, buf, pbuf
        ptr = pbuf.read_pointer

        raise Error, "no group found for '#{id}'" if val == 0 && ptr.null?
        raise Error, "no group found for '#{id}'" if val == Errno::ENOENT::Errno
        raise SystemCallError.new(fun, val) if val != 0

        ptr
      rescue Errno::ERANGE
        size += 1024
        raise if size > BUF_MAX
        buf = FFI::MemoryPointer.new(:char, size)
        retry
      end
    end

    private_class_method :lookup_group

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
        u.change       = Time.at(pwd[:pw_change])
        u.access_class = pwd[:pw_class]
        u.gecos        = pwd[:pw_gecos]
        u.dir          = pwd[:pw_dir]
        u.shell        = pwd[:pw_shell]
        u.expire       = Time.at(pwd[:pw_expire])
      end

      log = get_lastlog_info(user)

      if log
        if FREEBSD_UTX
          login_device = log[:ut_line].to_s
          login_host   = log[:ut_host].to_s

          user.login_time   = Time.at(log[:tv_sec]) if log[:tv_sec] > 0
          user.login_device = login_device unless login_device.empty?
          user.login_host   = login_host unless login_host.empty?
        else
          login_device = log[:ll_line].to_s
          login_host   = log[:ll_host].to_s

          user.login_time   = Time.at(log[:ll_time]) if log[:ll_time] > 0
          user.login_device = login_device unless login_device.empty?
          user.login_host   = login_host unless login_host.empty?
        end
      end

      user
    end

    private_class_method :get_user_from_struct

    # Get lastlog information for the given user.
    def self.get_lastlog_info(user)
      return get_utx_lastlogin_info(user.name) if FREEBSD_UTX

      logfile = '/var/log/lastlog'
      lastlog = LastlogStruct.new

      begin
        fd = open_c(logfile, File::RDONLY)

        if fd >= 0
          bytes = pread_c(fd, lastlog, lastlog.size, user.uid * lastlog.size)
          if bytes < 0
            raise Error, "pread function failed: #{strerror(FFI.errno)}"
          end
        else
          lastlog = nil # Ignore, most likely improper permissions
        end
      ensure
        close_c(fd) if fd && fd >= 0
      end

      lastlog
    end

    private_class_method :get_lastlog_info

    if FREEBSD_UTX
      # Gets last login information from FreeBSD's utx.lastlogin database.
      def self.get_utx_lastlogin_info(name)
        if setutxdb(UTXDB_LASTLOGIN, nil) != 0
          return nil
        end

        ptr = getutxuser(name)
        ptr.null? ? nil : UtmpxStruct.new(ptr)
      ensure
        endutxent()
      end

      private_class_method :get_utx_lastlogin_info
    end
  end
end
