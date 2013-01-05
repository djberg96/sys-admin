###############################################################################
# test_sys_admin_windows.rb
#
# Test suite for the Win32 version of sys-admin.  Note that some of the tests
# are numbered to ensure a certain order.  That way I can add test users
# before configuring or deleting them.
#
# It is assumed that this test will be run via the 'rake test' task.
###############################################################################
require 'test-unit'
require 'sys/admin'
require 'socket'
include Sys

class TC_Sys_Admin_Win32 < Test::Unit::TestCase
  def self.startup
    @@host = Socket.gethostname
  end

  def setup
    @user       = User.new
    @user_name  = 'Guest'
    @user_id    = 501        # best guess, may fail
    @group      = Group.new
    @group_name = 'Guests'
    @group_id   = 546        # best guess, may fail
  end

  # Admin singleton methods

  def test_01_add_user
    assert_respond_to(Admin, :add_user)
    assert_nothing_raised{
      Admin.add_user(:name => 'foo', :password => 'a1b2c3D4')
    }
  end

  def test_02_config_user
    assert_respond_to(Admin, :configure_user)
    assert_nothing_raised{
      Admin.configure_user(
        :name        => 'foo',
        :description => 'delete me',
        :fullname    => 'fubar',
        :password    => ['a1b2c3D4', 'd1c2b3A4']
      )
    }
  end

  def test_03_delete_user
    assert_respond_to(Admin, :delete_user)
    assert_nothing_raised{ Admin.delete_user('foo') }
  end

  def test_01_add_group
    assert_respond_to(Admin, :add_group)
    assert_nothing_raised{ Admin.add_group(:name => 'bar') }
  end

  def test_02_configure_group
    assert_respond_to(Admin, :configure_group)
    assert_nothing_raised{
       Admin.configure_group(:name => 'bar', :description => 'delete me')
    }
  end

  def test_03_delete_group
    assert_respond_to(Admin, :delete_group)
    assert_nothing_raised{ Admin.delete_group('bar') }
  end

  def test_get_login_basic
    assert_respond_to(Admin, :get_login)
    assert_nothing_raised{ Admin.get_login }
  end

  def test_get_login
    assert_kind_of(String, Admin.get_login)
  end

  def test_get_login_expected_errors
    assert_raise(ArgumentError){ Admin.get_login('foo') }
  end

  def test_get_user_basic
    assert_respond_to(Admin, :get_user)
  end

  def test_get_user_by_string
    assert_nothing_raised{ Admin.get_user(@user_name, :localaccount => true) }
    assert_kind_of(User, Admin.get_user(@user_name, :localaccount => true))
  end

  def test_get_user_by_uid
    assert_nothing_raised{ Admin.get_user(@user_id, :localaccount => true) }
    assert_kind_of(User, Admin.get_user(@user_id, :localaccount => true))
  end

  def test_get_user_by_string_with_options
    options = {:host => @@host, :localaccount => true}
    assert_nothing_raised{ Admin.get_user(@user_name, options) }
    assert_kind_of(User, Admin.get_user(@user_name, options))
  end

  def test_get_user_by_uid_with_options
    options = {:host => @@host, :localaccount => true}
    assert_nothing_raised{ Admin.get_user(@user_id, options) }
    assert_kind_of(User, Admin.get_user(@user_id, options))
  end

  def test_get_user_expected_errors
    assert_raises(ArgumentError){ Admin.get_user }
  end

  def test_users_basic
    assert_respond_to(Admin, :users)
    assert_nothing_raised{ Admin.users(:localaccount => true) }
  end

  def test_users
    assert_kind_of(Array, Admin.users(:localaccount => true))
    assert_kind_of(User, Admin.users(:localaccount => true).first)
  end

  def test_get_group_basic
    assert_respond_to(Admin, :get_group)
  end

  def test_get_group_by_name
    assert_nothing_raised{ Admin.get_group(@group_name, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_name, :localaccount => true))
  end

  def test_get_group_by_gid
    assert_nothing_raised{ Admin.get_group(@group_id, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_id, :localaccount => true))
  end

  def test_get_group_with_options
    assert_nothing_raised{ Admin.get_group(@group_name, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_name, :localaccount => true))
  end

  def test_get_group_expected_errors
    assert_raise(ArgumentError){ Admin.get_group }
  end

  def test_groups_basic
    assert_respond_to(Admin, :groups)
    assert_nothing_raised{ Admin.groups(:localaccount => true) }
  end

  def test_groups
    assert_kind_of(Array, Admin.groups(:localaccount => true))
    assert_kind_of(Group, Admin.groups(:localaccount => true).first)
  end

  # User class

  def test_user_instance_caption
    assert_respond_to(@user, :caption)
    assert_respond_to(@user, :caption=)
  end

  def test_user_instance_description
    assert_respond_to(@user, :description)
    assert_respond_to(@user, :description=)
  end

  def test_user_instance_domain
    assert_respond_to(@user, :domain)
    assert_respond_to(@user, :domain=)
  end

  def test_user_instance_password
    assert_respond_to(@user, :password)
    assert_respond_to(@user, :password=)
  end

  def test_user_instance_full_name
    assert_respond_to(@user, :full_name)
    assert_respond_to(@user, :full_name=)
  end

  def test_user_instance_name
    assert_respond_to(@user, :name)
    assert_respond_to(@user, :name=)
  end

  def test_user_instance_sid
    assert_respond_to(@user, :sid)
    assert_respond_to(@user, :sid=)
  end

  def test_user_instance_status
    assert_respond_to(@user, :status)
    assert_respond_to(@user, :status=)
  end

  def test_user_instance_disabled
    assert_respond_to(@user, :disabled?)
    assert_respond_to(@user, :disabled=)
  end

  def test_user_instance_local
    assert_respond_to(@user, :local?)
    assert_respond_to(@user, :local=)
  end

  def test_user_instance_lockout
    assert_respond_to(@user, :lockout?)
    assert_respond_to(@user, :lockout=)
  end

  def test_user_instance_password_changeable
    assert_respond_to(@user, :password_changeable?)
    assert_respond_to(@user, :password_changeable=)
  end

  def test_user_instance_password_expires
    assert_respond_to(@user, :password_expires?)
    assert_respond_to(@user, :password_expires=)
  end

  def test_user_instance_password_required
    assert_respond_to(@user, :password_required?)
    assert_respond_to(@user, :password_required=)
  end

  def test_user_instance_account_type
    assert_respond_to(@user, :account_type)
    assert_respond_to(@user, :account_type=)
  end

  def test_user_instance_uid
    assert_respond_to(@user, :uid)
    assert_respond_to(@user, :uid=)
  end

  def test_user_dir_basic
    assert_respond_to(@user, :dir)
    assert_respond_to(@user, :dir=)
  end

  def test_user_dir
    assert_nothing_raised{ @user = Admin.get_user(@user_name, :localaccount => true) }
    assert_kind_of([String, NilClass], @user.dir)
  end

  # Group class

  def test_group_instance_caption
    assert_respond_to(@group, :caption)
    assert_respond_to(@group, :caption=)
  end

  def test_group_instance_description
    assert_respond_to(@group, :description)
    assert_respond_to(@group, :description=)
  end

  def test_group_instance_domain
    assert_respond_to(@group, :domain)
    assert_respond_to(@group, :domain=)
  end

  def test_group_instance_install_date
    assert_respond_to(@group, :install_date)
    assert_respond_to(@group, :install_date=)
  end

  def test_group_instance_name
    assert_respond_to(@group, :name)
    assert_respond_to(@group, :name)
  end

  def test_group_instance_gid
    assert_respond_to(@group, :gid)
    assert_respond_to(@group, :gid=)
  end

  def test_group_instance_status
    assert_respond_to(@group, :status)
    assert_respond_to(@group, :status=)
  end

  def test_group_instance_sid
    assert_respond_to(@group, :sid)
    assert_respond_to(@group, :sid=)
  end

  def test_group_instance_sid_type
    assert_respond_to(@group, :sid_type)
    assert_respond_to(@group, :sid_type=)
  end

  def test_group_instance_local
    assert_respond_to(@group, :local?)
    assert_respond_to(@group, :local=)
  end

  def teardown
    @user       = nil
    @user_name  = nil
    @user_id    = nil
    @group      = nil
    @group_name = nil
    @group_id   = nil
  end

  def self.shutdown
    @@host = nil
  end
end
