require 'ffi'
require 'win32ole'
require 'win32/security'
require 'win32/registry'
require 'socket'

module Sys
  class Admin
    extend FFI::Library

    # This is the error raised in the majority of cases if anything goes wrong
    # with any of the Sys::Admin methods.
    #
    class Error < StandardError; end

    SidTypeUser           = 1
    SidTypeGroup          = 2
    SidTypeDomain         = 3
    SidTypeAlias          = 4
    SidTypeWellKnownGroup = 5
    SidTypeDeletedAccount = 6
    SidTypeInvalid        = 7
    SidTypeUnknown        = 8
    SidTypeComputer       = 9

    HKEY = 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\'
    private_constant :HKEY

    # Retrieves the user's home directory. For local accounts query the
    # registry. For domain accounts use ADSI and use the HomeDirectory.
    #
    def self.get_home_dir(user, local = false, domain = nil)
      if local
        sec = Win32::Security::SID.open(user)
        key = HKEY + sec.to_s
        dir = nil

        begin
          Win32::Registry::HKEY_LOCAL_MACHINE.open(key) do |reg|
            dir = reg['ProfileImagePath']
          end
        rescue Win32::Registry::Error
          # Not every local user has a home directory
        end
      else
        domain ||= Socket.gethostname
        adsi = WIN32OLE.connect("WinNT://#{domain}/#{user},user")
        dir = adsi.get('HomeDirectory')
      end

      dir
    end

    private_class_method :get_home_dir

    # A private method that lower cases all keys, and converts them
    # all to symbols.
    #
    def self.munge_options(opts)
      rhash = {}

      opts.each do |k, v|
        k = k.to_s.downcase.to_sym
        rhash[k] = v
      end

      rhash
    end

    private_class_method :munge_options

    # An internal, private method for getting a list of groups for
    # a particular user. The first member is a list of group names,
    # the second member is the primary group ID.
    #
    def self.get_groups(domain, user)
      array = []
      adsi = WIN32OLE.connect("WinNT://#{domain}/#{user},user")
      adsi.groups.each{ |g| array << g.name }
      [array, adsi.PrimaryGroupId]
    end

    private_class_method :get_groups

    # An internal, private method for getting a list of members for
    # any particular group.
    #
    def self.get_members(domain, group)
      array = []
      adsi = WIN32OLE.connect("WinNT://#{domain}/#{group}")
      adsi.members.each{ |g| array << g.name }
      array
    end

    private_class_method :get_members

    # Used by the get_login method
    ffi_lib :advapi32
    attach_function :GetUserNameW, [:pointer, :pointer], :bool
    private_class_method :GetUserNameW

    # Creates the given +user+. If no domain option is specified,
    # then it defaults to your local host, i.e. a local account is
    # created.
    #
    # Any options provided are treated as IADsUser interface methods
    # and are called before SetInfo is finally called.
    #
    # Examples:
    #
    #  # Create a local user with no options
    #  Sys::Admin.add_user(:name => 'asmith')
    #
    #  # Create a local user with options
    #  Sys::Admin.add_user(
    #     :name        => 'asmith',
    #     :description => 'Really cool guy',
    #     :password    => 'abc123'
    #  )
    #
    #  # Create a user on a specific domain
    #  Sys::Admin.add_user(
    #     :name     => 'asmith',
    #     :domain   => 'XX',
    #     :fullname => 'Al Smith'
    #  )
    #--
    # Most options are passed to the 'put' method. However, we handle the
    # password specially since it's a separate method, and some environments
    # require that it be set up front.
    #
    def self.add_user(options = {})
      options = munge_options(options)

      name   = options.delete(:name) or raise ArgumentError, 'No user given'
      domain = options[:domain]

      if domain.nil?
        domain  = Socket.gethostname
        moniker = "WinNT://#{domain},Computer"
      else
        moniker = "WinNT://#{domain}"
      end

      begin
        adsi = WIN32OLE.connect(moniker)
        user = adsi.create('user', name)

        options.each do |option, value|
          if option.to_s == 'password'
            user.setpassword(value)
          else
            user.put(option.to_s, value)
          end
        end

        user.setinfo
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Configures the +user+ using +options+. If no domain option is
    # specified then your local host is used, i.e. you are configuring
    # a local user account.
    #
    # See http://tinyurl.com/3hjv9 for a list of valid options.
    #
    # In the case of a password change, pass a two element array as the
    # old value and new value.
    #
    # Examples:
    #
    #  # Configure a local user
    #  Sys::Admin.configure_user(
    #     :name        => 'djberge',
    #     :description => 'Awesome'
    #  )
    #
    #  # Change the password
    #  Sys::Admin.configure_user(
    #     :name     => 'asmith',
    #     :password => 'new_password'
    #  )
    #
    #  # Configure a user on a specific domain
    #  Sys::Admin.configure_user(
    #     :name      => 'jsmrz',
    #     :domain    => 'XX',
    #     :firstname => 'Jo'
    #  )
    #
    def self.configure_user(options = {})
      options = munge_options(options)

      name   = options.delete(:name) or raise ArgumentError, 'No name given'
      domain = options[:domain] || Socket.gethostname

      begin
        adsi = WIN32OLE.connect("WinNT://#{domain}/#{name},user")

        options.each do |option, value|
          if option.to_s == 'password'
            adsi.setpassword(value)
          else
            adsi.put(option.to_s, value)
          end
        end

        adsi.setinfo
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Deletes the given +user+ on +domain+. If no domain is specified,
    # then it defaults to your local host, i.e. a local account is
    # deleted.
    #
    def self.delete_user(user, domain = nil)
      if domain.nil?
        domain  = Socket.gethostname
        moniker = "WinNT://#{domain},Computer"
      else
        moniker = "WinNT://#{domain}"
      end

      begin
        adsi = WIN32OLE.connect(moniker)
        adsi.delete('user', user)
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Create a new +group+ using +options+. If no domain option is specified
    # then a local group is created instead.
    #
    # Examples:
    #
    #  # Create a local group with no options
    #  Sys::Admin.add_group(:name => 'Dudes')
    #
    #  # Create a local group with options
    #  Sys::Admin.add_group(:name => 'Dudes', :description => 'Boys')
    #
    #  # Create a group on a specific domain
    #  Sys::Admin.add_group(
    #     :name        => 'Ladies',
    #     :domain      => 'XYZ',
    #     :description => 'Girls'
    #  )
    #
    def self.add_group(options = {})
      options = munge_options(options)

      group  = options.delete(:name) or raise ArgumentError, 'No name given'
      domain = options[:domain]

      if domain.nil?
        domain  = Socket.gethostname
        moniker = "WinNT://#{domain},Computer"
      else
        moniker = "WinNT://#{domain}"
      end

      begin
        adsi = WIN32OLE.connect(moniker)
        group = adsi.create('group', group)
        group.setinfo
        configure_group(options) unless options.empty?
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Adds +user+ to +group+ on the specified +domain+, or the localhost
    # if no domain is specified.
    #
    def self.add_group_member(user, group, domain=nil)
      domain ||= Socket.gethostname
      adsi = WIN32OLE.connect("WinNT://#{domain}/#{group},group")
      adsi.Add("WinNT://#{domain}/#{user}")
    rescue WIN32OLERuntimeError => err
      raise Error, err
    end

    # Removes +user+ from +group+ on the specified +domain+, or the localhost
    # if no domain is specified.
    #
    def self.remove_group_member(user, group, domain=nil)
      domain ||= Socket.gethostname
      adsi = WIN32OLE.connect("WinNT://#{domain}/#{group},group")
      adsi.Remove("WinNT://#{domain}/#{user}")
    rescue WIN32OLERuntimeError => err
      raise Error, err
    end

    # Configures the +group+ using +options+. If no domain option is
    # specified then your local host is used, i.e. you are configuring
    # a local group.
    #
    # See http://tinyurl.com/cjkzl for a list of valid options.
    #
    # Examples:
    #
    #  # Configure a local group.
    #  Sys::Admin.configure_group(:name => 'Abba', :description => 'Swedish')
    #
    #  # Configure a group on a specific domain.
    #  Sys::Admin.configure_group(
    #     :name        => 'Web Team',
    #     :domain      => 'Foo',
    #     :description => 'Web programming cowboys'
    #  )
    #
    def self.configure_group(options = {})
      options = munge_options(options)

      group  = options.delete(:name) or raise ArgumentError, 'No name given'
      domain = options[:domain] || Socket.gethostname

      begin
        adsi = WIN32OLE.connect("WinNT://#{domain}/#{group},group")
        options.each{ |option, value| adsi.put(option.to_s, value) }
        adsi.setinfo
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Delete the +group+ from +domain+. If no domain is specified, then
    # you are deleting a local group.
    #
    def self.delete_group(group, domain = nil)
      if domain.nil?
        domain = Socket.gethostname
        moniker = "WinNT://#{domain},Computer"
      else
        moniker = "WinNT://#{domain}"
      end

      begin
        adsi = WIN32OLE.connect(moniker)
        adsi.delete('group', group)
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end
    end

    # Returns the user name (only) of the current login.
    #
    def self.get_login
      buffer = FFI::MemoryPointer.new(:char, 256)
      nsize  = FFI::MemoryPointer.new(:ulong)
      nsize.write_ulong(buffer.size)

      unless GetUserNameW(buffer, nsize)
        raise Error, 'GetUserName() call failed in get_login'
      end

      buffer.read_string(nsize.read_ulong * 2).tr(0.chr, '')
    end

    # Returns a User object based on either +name+ or +uid+.
    #
    # call-seq:
    #    Sys::Admin.get_user(name, options = {})
    #    Sys::Admin.get_user(uid, options = {})
    #
    # Looks for +usr+ information based on the options you specify, where
    # the +usr+ argument can be either a user name or a RID.
    #
    # If a 'host' option is specified, information is retrieved from that
    # host. Otherwise, the local host is used.
    #
    # All other options are converted to WQL statements against the
    # Win32_UserAccount WMI object. See http://tinyurl.com/by9nvn for a
    # list of possible options.
    #
    # Examples:
    #
    #  # Get a user by name
    #  Admin.get_user('djberge')
    #
    #  # Get a user by uid
    #  Admin.get_user(100)
    #
    #  # Get a user on a specific domain
    #  Admin.get_user('djberge', :domain => 'TEST')
    #--
    # The reason for keeping the +usr+ variable as a separate argument
    # instead of rolling it into the options hash was to keep a unified
    # API between the Windows and UNIX versions.
    #
    def self.get_user(usr, options = {})
      options = munge_options(options)

      host = options.delete(:host) || Socket.gethostname
      cs = 'winmgmts:{impersonationLevel=impersonate}!'
      cs << "//#{host}/root/cimv2"

      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end

      query = 'select * from win32_useraccount'

      i = 0

      options.each do |opt, val|
        if i == 0
          query << " where #{opt} = '#{val}'"
          i += 1
        else
          query << " and #{opt} = '#{val}'"
        end
      end

      if usr.kind_of?(Numeric)
        if i == 0
          query << " where sid like '%-#{usr}'"
        else
          query << " and sid like '%-#{usr}'"
        end
      else
        if i == 0
          query << " where name = '#{usr}'"
        else
          query << " and name = '#{usr}'"
        end
      end

      domain = options[:domain] || host

      wmi.execquery(query).each do |user|
        uid = user.sid.split('-').last.to_i

        # Because our 'like' query isn't fulproof, let's parse
        # the SID again to make sure
        if usr.kind_of?(Numeric)
          next if usr != uid
        end

        groups, primary_group = *get_groups(domain, user.name)

        user_object = User.new do |u|
          u.account_type        = user.accounttype
          u.caption             = user.caption
          u.description         = user.description
          u.disabled            = user.disabled
          u.domain              = user.domain
          u.full_name           = user.fullname
          u.install_date        = user.installdate
          u.local               = user.localaccount
          u.lockout             = user.lockout
          u.name                = user.name
          u.password_changeable = user.passwordchangeable
          u.password_expires    = user.passwordexpires
          u.password_required   = user.passwordrequired
          u.sid                 = user.sid
          u.sid_type            = user.sidtype
          u.status              = user.status
          u.uid                 = uid
          u.gid                 = primary_group
          u.groups              = groups
          u.dir                 = get_home_dir(user.name, options[:localaccount], domain)
        end

        return user_object
      end

      # If we're here, it means it wasn't found.
      raise Error, "no user found for '#{usr}'"
    end

    # Returns an array of User objects for each user on the system.
    #
    # You may specify a host from which information is retrieved. The
    # default is the local host.
    #
    # All other arguments are passed as WQL query parameters against
    # the Win32_UserAccont WMI object.
    #
    # Examples:
    #
    #  # Get all local account users
    #  Sys::Admin.users(:localaccount => true)
    #
    #  # Get all user accounts on a specific domain
    #  Sys::Admin.users(:domain => 'FOO')
    #
    #  # Get a single user from a domain
    #  Sys::Admin.users(:name => 'djberge', :domain => 'FOO')
    #
    def self.users(options = {})
      options = munge_options(options)

      host = options.delete(:host) || Socket.gethostname
      cs = 'winmgmts:{impersonationLevel=impersonate}!'
      cs << "//#{host}/root/cimv2"

      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => e
        raise Error, e
      end

      query = 'select * from win32_useraccount'

      i = 0

      options.each do |opt, val|
        if i == 0
          query << " where #{opt} = '#{val}'"
          i += 1
        else
          query << " and #{opt} = '#{val}'"
        end
      end

      array = []
      domain = options[:domain] || host

      wmi.execquery(query).each do |user|
        uid = user.sid.split('-').last.to_i

        usr = User.new do |u|
          u.account_type        = user.accounttype
          u.caption             = user.caption
          u.description         = user.description
          u.disabled            = user.disabled
          u.domain              = user.domain
          u.full_name           = user.fullname
          u.install_date        = user.installdate
          u.local               = user.localaccount
          u.lockout             = user.lockout
          u.name                = user.name
          u.password_changeable = user.passwordchangeable
          u.password_expires    = user.passwordexpires
          u.password_required   = user.passwordrequired
          u.sid                 = user.sid
          u.sid_type            = user.sidtype
          u.status              = user.status
          u.groups              = get_groups(domain, user.name)
          u.uid                 = uid
          u.dir                 = get_home_dir(user.name, options[:localaccount], host)
        end

        array.push(usr)
      end

      array
    end

    # Returns a Group object based on either +name+ or +gid+.
    #
    # call-seq:
    #    Sys::Admin.get_group(name, options = {})
    #    Sys::Admin.get_group(gid, options = {})
    #
    # If a numeric value is sent as the first parameter, it is treated
    # as a RID and is checked against the SID for a match.
    #
    # You may specify a host as an option from which information is
    # retrieved. The default is the local host.
    #
    # All other options are passed as WQL parameters to the Win32_Group
    # WMI object. See http://tinyurl.com/bngc8s for a list of possible
    # options.
    #
    # Examples:
    #
    #  # Find a group by name
    #  Sys::Admin.get_group('Web Team')
    #
    #  # Find a group by id
    #  Sys::Admin.get_group(31667)
    #
    #  # Find a group on a specific domain
    #  Sys::Admin.get_group('Web Team', :domain => 'FOO')
    #
    def self.get_group(grp, options = {})
      options = munge_options(options)

      host = options.delete(:host) || Socket.gethostname
      cs = 'winmgmts:{impersonationLevel=impersonate}!'
      cs << "//#{host}/root/cimv2"

      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end

      query = 'select * from win32_group'

      i = 0

      options.each do |opt, val|
        if i == 0
          query << " where #{opt} = '#{val}'"
          i += 1
        else
          query << " and #{opt} = '#{val}'"
        end
      end

      if grp.kind_of?(Integer)
        if i == 0
          query << " where sid like '%-#{grp}'"
        else
          query << " and sid like '%-#{grp}'"
        end
      else
        if i == 0
          query << " where name = '#{grp}'"
        else
          query << " and name = '#{grp}'"
        end
      end

      domain = options[:domain] || host

      wmi.execquery(query).each do |group|
        gid = group.sid.split('-').last.to_i

        # Because our 'like' query isn't fulproof, let's parse
        # the SID again to make sure
        if grp.kind_of?(Integer)
          next if grp != gid
        end

        group_object = Group.new do |g|
          g.caption      = group.caption
          g.description  = group.description
          g.domain       = group.domain
          g.gid          = gid
          g.install_date = group.installdate
          g.local        = group.localaccount
          g.name         = group.name
          g.sid          = group.sid
          g.sid_type     = group.sidtype
          g.status       = group.status
          g.members      = get_members(domain, group.name)
        end

        return group_object
      end

      # If we're here, it means it wasn't found.
      raise Error, "no group found for '#{grp}'"
    end

    # Returns an array of Group objects for each user on the system.
    #
    # You may specify a host option from which information is retrieved.
    # The default is the local host.
    #
    # All other options are passed as WQL parameters to the Win32_Group
    # WMI object. See http://tinyurl.com/bngc8s for a list of possible
    # options.
    #
    # Examples:
    #
    #  # Get local group information
    #  Sys::Admin.groups(:localaccount => true)
    #
    #  # Get all groups on a specific domain
    #  Sys::Admin.groups(:domain => 'FOO')
    #
    #  # Get a specific group on a domain
    #  Sys::Admin.groups(:name => 'Some Group', :domain => 'FOO')
    #
    def self.groups(options = {})
      options = munge_options(options)

      host = options.delete(:host) || Socket.gethostname
      cs = 'winmgmts:{impersonationLevel=impersonate}!'
      cs << "//#{host}/root/cimv2"

      begin
        wmi = WIN32OLE.connect(cs)
      rescue WIN32OLERuntimeError => err
        raise Error, err
      end

      query = 'select * from win32_group'

      i = 0

      options.each do |opt, val|
        if i == 0
          query << " where #{opt} = '#{val}'"
          i += 1
        else
          query << " and #{opt} = '#{val}'"
        end
      end

      array = []
      domain = options[:domain] || host

      wmi.execquery(query).each do |group|
        grp = Group.new do |g|
          g.caption      = group.caption
          g.description  = group.description
          g.domain       = group.domain
          g.gid          = group.sid.split('-').last.to_i
          g.install_date = group.installdate
          g.local        = group.localaccount
          g.name         = group.name
          g.sid          = group.sid
          g.sid_type     = group.sidtype
          g.status       = group.status
          g.members      = get_members(domain, group.name)
        end

        array.push(grp)
      end

      array
    end

    class User
      # An account for users whose primary account is in another domain.
      TEMP_DUPLICATE = 0x0100

      # Default account type that represents a typical user.
      NORMAL = 0x0200

      # A permit to trust account for a domain that trusts other domains.
      INTERDOMAIN_TRUST = 0x0800

      # An account for a Windows NT/2000 workstation or server that is a
      # member of this domain.
      WORKSTATION_TRUST = 0x1000

      # A computer account for a backup domain controller that is a member
      # of this domain.
      SERVER_TRUST = 0x2000

      # Domain and username of the account.
      attr_accessor :caption

      # Description of the account.
      attr_accessor :description

      # Name of the Windows domain to which a user account belongs.
      attr_accessor :domain

      # The user's password.
      attr_accessor :password

      # Full name of a local user.
      attr_accessor :full_name

      # An array of groups to which the user belongs.
      attr_accessor :groups

      # Date the user account was created.
      attr_accessor :install_date

      # Name of the Windows user account on the domain that the User#domain
      # property specifies.
      attr_accessor :name

      # The user's security identifier.
      attr_accessor :sid

      # Current status for the user, such as "ok", "error", etc.
      attr_accessor :status

      # The user's id (RID).
      attr_accessor :uid

      # The user's primary group ID.
      attr_accessor :gid

      # The user's home directory
      attr_accessor :dir

      # Used to set whether or not the account is disabled.
      attr_writer :disabled

      # Sets whether or not the account is defined on the local computer.
      attr_writer :local

      # Sets whether or not the account is locked out of the OS.
      attr_writer :lockout

      # Sets whether or not the password for the account can be changed.
      attr_writer :password_changeable

      # Sets whether or not the password for the account expires.
      attr_writer :password_expires

      # Sets whether or not a password is required for the account.
      attr_writer :password_required

      # Returns the account type as a human readable string.
      attr_reader :account_type

      # Creates an returns a new User object.  A User object encapsulates a
      # user account on the operating system.
      #
      # Yields +self+ if a block is provided.
      #
      def initialize
        yield self if block_given?
      end

      # Sets the account type for the account.  Possible values are:
      #
      # * User::TEMP_DUPLICATE
      # * User::NORMAL
      # * User::INTERDOMAIN_TRUST
      # * User::WORKSTATION_TRUST
      # * User::SERVER_TRUST
      #
      def account_type=(type)
        case type
          when TEMP_DUPLICATE
            @account_type = 'duplicate'
          when NORMAL
            @account_type = 'normal'
          when INTERDOMAIN_TRUST
            @account_type = 'interdomain_trust'
          when WORKSTATION_TRUST
            @account_type = 'workstation_trust'
          when SERVER_TRUST
            @account_type = 'server_trust'
          else
            @account_type = 'unknown'
        end
      end

      # Returns the SID type as a human readable string.
      #
      def sid_type
        @sid_type
      end

      # Sets the SID (Security Identifier) type to +stype+, which can be
      # one of the following constant values:
      #
      # * Admin::SidTypeUser
      # * Admin::SidTypeGroup
      # * Admin::SidTypeDomain
      # * Admin::SidTypeAlias
      # * Admin::SidTypeWellKnownGroup
      # * Admin::SidTypeDeletedAccount
      # * Admin::SidTypeInvalid
      # * Admin::SidTypeUnknown
      # * Admin::SidTypeComputer
      #
      def sid_type=(stype)
        case stype
          when Admin::SidTypeUser
            @sid_type = 'user'
          when Admin::SidTypeGroup
            @sid_type = 'group'
          when Admin::SidTypeDomain
            @sid_type = 'domain'
          when Admin::SidTypeAlias
            @sid_type = 'alias'
          when Admin::SidTypeWellKnownGroup
            @sid_type = 'well_known_group'
          when Admin::SidTypeDeletedAccount
            @sid_type = 'deleted_account'
          when Admin::SidTypeInvalid
            @sid_type = 'invalid'
          when Admin::SidTypeUnknown
            @sid_type = 'unknown'
          when Admin::SidTypeComputer
            @sid_type = 'computer'
          else
            @sid_type = 'unknown'
        end
      end

      # Returns whether or not the account is disabled.
      #
      def disabled?
        @disabled
      end

      # Returns whether or not the account is local.
      #
      def local?
        @local
      end

      # Returns whether or not the account is locked out.
      #
      def lockout?
        @lockout
      end

      # Returns whether or not the password for the account is changeable.
      #
      def password_changeable?
        @password_changeable
      end

      # Returns whether or not the password for the account is changeable.
      #
      def password_expires?
        @password_expires
      end

      # Returns whether or not the a password is required for the account.
      #
      def password_required?
        @password_required
      end
    end

    class Group
      # Short description of the object.
      attr_accessor :caption

      # Description of the group.
      attr_accessor :description

      # Name of the Windows domain to which the group account belongs.
      attr_accessor :domain

      # Date the group was added.
      attr_accessor :install_date

      # Name of the Windows group account on the Group#domain specified.
      attr_accessor :name

      # Security identifier for this group.
      attr_accessor :sid

      # Current status for the group, such as "ok", "error", etc.
      attr_accessor :status

      # The group ID.
      attr_accessor :gid

      # Sets whether or not the group is local (as opposed to global).
      attr_writer :local

      # An array of members for that group. May contain SID's.
      attr_accessor :members

      # Creates and returns a new Group object.  This class encapsulates
      # the information for a group account, whether it be global or local.
      #
      # Yields +self+ if a block is given.
      #
      def initialize
        yield self if block_given?
      end

      # Returns whether or not the group is a local group.
      #
      def local?
        @local
      end

      # Returns the type of SID (Security Identifier) as a stringified value.
      #
      def sid_type
        @sid_type
      end

      # Sets the SID (Security Identifier) type to +stype+, which can be
      # one of the following constant values:
      #
      # * Admin::SidTypeUser
      # * Admin::SidTypeGroup
      # * Admin::SidTypeDomain
      # * Admin::SidTypeAlias
      # * Admin::SidTypeWellKnownGroup
      # * Admin::SidTypeDeletedAccount
      # * Admin::SidTypeInvalid
      # * Admin::SidTypeUnknown
      # * Admin::SidTypeComputer
      #
      def sid_type=(stype)
        if stype.kind_of?(String)
          @sid_type = stype.downcase
        else
          case stype
            when Admin::SidTypeUser
              @sid_type = 'user'
            when Admin::SidTypeGroup
              @sid_type = 'group'
            when Admin::SidTypeDomain
              @sid_type = 'domain'
            when Admin::SidTypeAlias
              @sid_type = 'alias'
            when Admin::SidTypeWellKnownGroup
              @sid_type = 'well_known_group'
            when Admin::SidTypeDeletedAccount
              @sid_type = 'deleted_account'
            when Admin::SidTypeInvalid
              @sid_type = 'invalid'
            when Admin::SidTypeUnknown
              @sid_type = 'unknown'
            when Admin::SidTypeComputer
              @sid_type = 'computer'
             else
              @sid_type = 'unknown'
          end
        end

        @sid_type
      end
    end
  end
end
