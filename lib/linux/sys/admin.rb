require 'sys/admin/custom'
require 'sys/admin/common'

# The Linux specific code.

module Sys
  class Admin
    private

    # I'm making some aliases here to prevent potential conflicts
    attach_function :open_c, :open, [:string, :int], :int
    attach_function :pread_c, :pread, [:int, :pointer, :size_t, :off_t], :size_t
    attach_function :close_c, :close, [:int], :int

    attach_function :getlogin_r, [:pointer, :size_t], :int
    attach_function :getpwnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getpwuid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getpwent_r, [:pointer, :pointer, :size_t, :pointer], :int
=begin
    attach_function :getgrnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getgrgid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int

    private_class_method :getlogin_r, :getpwnam_r, :getpwuid_r, :getgrnam_r
    private_class_method :getgrgid_r, :getlastlogx
=end

    # struct passwd from /usr/include/pwd.h
    class PasswdStruct < FFI::Struct
      layout(
        :pw_name, :string,
        :pw_passwd, :string,
        :pw_uid, :uint,
        :pw_gid, :uint,
        :pw_gecos, :string,
        :pw_dir, :string,
        :pw_shell, :string
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

    # I'm blending the timeval struct in directly here
    class LastlogStruct < FFI::Struct
      layout(
        :ll_time, :uint,
        :ll_line, [:char, 32],
        :ll_host, [:char, 256]
      )
    end

    #p check_sizeof('struct lastlog', 'utmp.h')
    #p LastlogStruct.size

    public

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

      buf  = FFI::MemoryPointer.new(:char, 1024)
      pbuf = FFI::MemoryPointer.new(PasswdStruct)
      temp = PasswdStruct.new

      begin
        setpwent()

        while getpwent_r(temp, buf, buf.size, pbuf) == 0
          ptr = pbuf.read_pointer

          break if ptr.null?

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

    # Note: it seems that Linux, or at least Ubuntu, does not track logins
    # via GDM (Gnome Display Manager) for some reason, so this may not return
    # anything useful.
    #
    # The use of pread was necessary here because it's a sparse file.
    #
    def self.get_lastlog_info(uid)
      logfile = '/var/log/lastlog'
      lastlog = LastlogStruct.new

      begin
        fd = open_c(logfile, File::RDONLY)

        if fd != -1
          bytes = pread_c(fd, lastlog, lastlog.size, uid * lastlog.size)
          if bytes < 0
            raise Error, "pread function failed: " + strerror(FFI.errno)
          end
        else
          nil # Ignore, improper permissions
        end
      ensure
        close_c(fd) if fd && fd >= 0
      end

      lastlog
    end
  end
end
