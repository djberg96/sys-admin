require 'sys/admin/custom'
require 'sys/admin/common'

# The Darwin specific code.

module Sys
  class Admin
    private

    # :no-doc:
    BUF_MAX = 65536 # Max buf size for retry.

    attach_function :getlogin_r, [:pointer, :int], :int
    attach_function :getpwnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getpwuid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getgrnam_r, [:string, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getgrgid_r, [:long, :pointer, :pointer, :size_t, :pointer], :int
    attach_function :getlastlogx, [:long, :pointer], :pointer

    private_class_method :getlogin_r, :getpwnam_r, :getpwuid_r, :getgrnam_r
    private_class_method :getgrgid_r, :getlastlogx

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
        :pw_expire, :ulong
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
    class LastlogxStruct < FFI::Struct
      layout(
        :tv_sec, :long,
        :tv_usec, :long,
        :ll_line, [:char, 32],
        :ll_host, [:char, 256]
      )
    end

    public

    # Returns the login for the current process.
    #
    def self.get_login
      buf = FFI::MemoryPointer.new(:char, 256)

      if getlogin_r(buf, buf.size) != 0
        raise Error, "getlogin_r function failed: " + strerror(FFI.errno)
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
      pbuf = FFI::MemoryPointer.new(PasswdStruct)
      temp = GroupStruct.new

      begin
        if gid.is_a?(String)
          val = getgrnam_r(gid, temp, buf, buf.size, pbuf)
          fun = 'getgrnam_r'
        else
          val = getgrgid_r(gid, temp, buf, buf.size, pbuf)
          fun = 'getgrgid_r'
        end
        raise SystemCallError.new(fun, val) if val != 0
      rescue Errno::ERANGE
        size += 1024
        raise if size > BUF_MAX
        buf = FFI::MemoryPointer.new(:char, size)
        retry
      end

      ptr = pbuf.read_pointer

      if ptr.null?
        raise Error, "no group found for '#{gid}'"
      end

      grp = GroupStruct.new(ptr)
      get_group_from_struct(grp)
    end

    # Returns an array of User objects for each user on the system.
    #
    #--
    # This method is somewhat slow on OSX because of the call to get
    # lastlog information. I'm not sure why.
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
        u.change       = Time.at(pwd[:pw_change])
        u.access_class = pwd[:pw_class]
        u.gecos        = pwd[:pw_gecos]
        u.dir          = pwd[:pw_dir]
        u.shell        = pwd[:pw_shell]
        u.expire       = Time.at(pwd[:pw_expire])
      end

      log = get_lastlog_info(user.uid)

      if log
        user.login_time = Time.at(log[:tv_sec])
        user.login_device = log[:ll_line].to_s
        user.login_host = log[:ll_host].to_s
      end

      user
    end

    # Gets lastlog information for the given user.
    def self.get_lastlog_info(uid)
      lastlog = LastlogxStruct.new

      # We don't check for failure here because most will fail due to
      # lack of permissions and/or simple lack of information.
      ptr = getlastlogx(uid, lastlog)

      ptr.null? ? nil : lastlog
    end
  end
end
