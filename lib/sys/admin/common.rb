# frozen_string_literal: true

require 'ffi'

# The Sys module serves as a namespace only.
module Sys

  # The Admin class provides a unified, cross platform replacement
  # for the Etc module.
  class Admin
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function :strerror, [:int], :string

    attach_function :getlogin, [], :string
    attach_function :getuid, [], :long
    attach_function :geteuid, [], :long
    attach_function :getpwnam, [:string], :pointer
    attach_function :getpwuid, [:long], :pointer
    attach_function :getpwent, [], :pointer
    attach_function :setpwent, [], :void
    attach_function :endpwent, [], :void

    attach_function :getgrgid, [:long], :pointer
    attach_function :getgrnam, [:string], :pointer
    attach_function :getgrent, [], :pointer
    attach_function :endgrent, [], :void
    attach_function :setgrent, [], :void

    private_class_method :getlogin, :getuid, :geteuid, :getpwnam, :getpwuid
    private_class_method :getpwent, :setpwent, :endpwent, :getgrgid, :getgrnam
    private_class_method :getgrent, :endgrent, :setgrent, :strerror

    # Error typically raised if any of the Sys::Admin methods fail.
    class Error < StandardError; end

    # The User class encapsulates the information found in /etc/passwd.
    class User
      # The user name associated with the account.
      attr_accessor :name

      # The user's encrypted password. Deprecated by /etc/shadow.
      attr_accessor :passwd

      # The user's user ID.
      attr_accessor :uid

      # The user's group ID.
      attr_accessor :gid

      # Next date a password change will be needed.
      attr_accessor :change

      # A comment field. Rarely used now.
      attr_accessor :gecos

      # The user's alloted amount of disk space.
      attr_accessor :quota

      # The absolute path name of the user's home directory.
      attr_accessor :dir

      # The user's login shell.
      attr_accessor :shell

      # The account's expiration date
      attr_accessor :expire

      # TODO: Forgot what this is.
      attr_accessor :fields

      # The user's access class.
      attr_accessor :access_class

      # Another comment field.
      attr_accessor :comment

      # Used in the past for password aging. Deprecated by /etc/shadow.
      attr_accessor :age

      # The last time the user logged in.
      attr_accessor :login_time

      # The host name from which the user last logged in.
      attr_accessor :login_host

      # The name of the terminal device the user last logged on with.
      attr_accessor :login_device

      # Creates and returns a User object, which encapsulates the information
      # typically found within an /etc/passwd entry, i.e. a struct passwd.
      #
      # If a block is provided, yields the object back to the block.
      #
      def initialize
        yield self if block_given?
      end

      # An array of groups to which the user belongs.
      def groups
        array = []

        Sys::Admin.groups.each do |grp|
          array << grp.name if grp.members.include?(name)
        end

        array
      end
    end

    # The Group class encapsulates information found in /etc/group.
    class Group
      # The name of the group.
      attr_accessor :name

      # The group's group ID.
      attr_accessor :gid

      # An array of members associated with the group.
      attr_accessor :members

      # The group password, if any.
      attr_accessor :passwd

      # Creates and returns a Group object, which encapsulates the information
      # typically found within an /etc/group entry, i.e. a struct group.
      #
      # If a block is provided, yields the object back to the block.
      #
      def initialize
        yield self if block_given?
      end
    end
  end
end
