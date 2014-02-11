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
require 'win32/security'
require 'socket'
include Sys

class TC_Sys_Admin_Win32 < Test::Unit::TestCase
  def self.startup
    @@host = Socket.gethostname
    @@elevated = Win32::Security.elevated_security?
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
    omit_unless(@@elevated)
    assert_respond_to(Admin, :add_user)
    assert_nothing_raised{
      Admin.add_user(:name => 'foo', :password => 'a1b2c3D4')
    }
  end

  def test_02_config_user
    omit_unless(@@elevated)
    assert_respond_to(Admin, :configure_user)
    assert_nothing_raised{
      Admin.configure_user(
        :name        => 'foo',
        :description => 'delete me',
        :fullname    => 'fubar',
        :password    => 'd1c2b3A4'
      )
    }
  end

  def test_06_delete_user
    omit_unless(@@elevated)
    assert_respond_to(Admin, :delete_user)
    assert_nothing_raised{ Admin.delete_user('foo') }
  end

  def test_01_add_group
    omit_unless(@@elevated)
    assert_respond_to(Admin, :add_group)
    assert_nothing_raised{ Admin.add_group(:name => 'bar') }
  end

  def test_02_configure_group
    omit_unless(@@elevated)
    assert_respond_to(Admin, :configure_group)
    assert_nothing_raised{
      Admin.configure_group(:name => 'bar', :description => 'delete me')
    }
  end

  def test_03_add_group_member
    omit_unless(@@elevated)
    assert_respond_to(Admin, :add_group_member)
    assert_nothing_raised{ Admin.add_group_member('foo', 'bar') }
  end

  def test_04_remove_group_member
    omit_unless(@@elevated)
    assert_respond_to(Admin, :remove_group_member)
    assert_nothing_raised{ Admin.remove_group_member('foo', 'bar') }
  end

  def test_05_delete_group
    omit_unless(@@elevated)
    assert_respond_to(Admin, :delete_group)
    assert_nothing_raised{ Admin.delete_group('bar') }
  end

  test "get_login basic functionality" do
    assert_respond_to(Admin, :get_login)
    assert_nothing_raised{ Admin.get_login }
  end

  test "get_login returns a string" do
    assert_kind_of(String, Admin.get_login)
    assert_true(Admin.get_login.size > 0)
  end

  test "get_login does not accept any arguments" do
    assert_raise(ArgumentError){ Admin.get_login('foo') }
  end

  test "get_user basic functionality" do
    assert_respond_to(Admin, :get_user)
  end

  test "get_user with string argument works as expected" do
    assert_nothing_raised{ Admin.get_user(@user_name, :localaccount => true) }
    assert_kind_of(User, Admin.get_user(@user_name, :localaccount => true))
  end

  test "get user with integer argument works as expected" do
    assert_nothing_raised{ Admin.get_user(@user_id, :localaccount => true) }
    assert_kind_of(User, Admin.get_user(@user_id, :localaccount => true))
  end

  test "get_user method by string accepts a hash of options" do
    options = {:host => @@host, :localaccount => true}
    assert_nothing_raised{ Admin.get_user(@user_name, options) }
    assert_kind_of(User, Admin.get_user(@user_name, options))
  end

  test "get_user method by uid accepts a hash of options" do
    options = {:host => @@host, :localaccount => true}
    assert_nothing_raised{ Admin.get_user(@user_id, options) }
    assert_kind_of(User, Admin.get_user(@user_id, options))
  end

  test "get_user method requires an argument" do
    assert_raises(ArgumentError){ Admin.get_user }
  end

  test "users method basic functionality" do
    assert_respond_to(Admin, :users)
    assert_nothing_raised{ Admin.users(:localaccount => true) }
  end

  test "users method returns an array of User objects" do
    assert_kind_of(Array, Admin.users(:localaccount => true))
    assert_kind_of(User, Admin.users(:localaccount => true).first)
  end

  test "get_group basic functionality" do
    assert_respond_to(Admin, :get_group)
  end

  test "get_group method returns expected results with a string argument" do
    assert_nothing_raised{ Admin.get_group(@group_name, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_name, :localaccount => true))
  end

  test "get_group method returns expected results with an integer argument" do
    assert_nothing_raised{ Admin.get_group(@group_id, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_id, :localaccount => true))
  end

  # TODO: Update
  test "get_group method accepts a hash of options" do
    assert_nothing_raised{ Admin.get_group(@group_name, :localaccount => true) }
    assert_kind_of(Group, Admin.get_group(@group_name, :localaccount => true))
  end

  test "get_group method requires an argument" do
    assert_raise(ArgumentError){ Admin.get_group }
  end

  test "get_groups method basic functionality" do
    assert_respond_to(Admin, :groups)
    assert_nothing_raised{ Admin.groups(:localaccount => true) }
  end

  test "get_groups method returns an array of Group objects" do
    assert_kind_of(Array, Admin.groups(:localaccount => true))
    assert_kind_of(Group, Admin.groups(:localaccount => true).first)
  end

  # User class

  test "caption accessor for User class" do
    assert_respond_to(@user, :caption)
    assert_respond_to(@user, :caption=)
  end

  test "description accessor for User class" do
    assert_respond_to(@user, :description)
    assert_respond_to(@user, :description=)
  end

  test "domain accessor for User class" do
    assert_respond_to(@user, :domain)
    assert_respond_to(@user, :domain=)
  end

  test "password accessor for User class" do
    assert_respond_to(@user, :password)
    assert_respond_to(@user, :password=)
  end

  test "full_name accessor for User class" do
    assert_respond_to(@user, :full_name)
    assert_respond_to(@user, :full_name=)
  end

  test "name accessor for User class" do
    assert_respond_to(@user, :name)
    assert_respond_to(@user, :name=)
  end

  test "sid accessor for User class" do
    assert_respond_to(@user, :sid)
    assert_respond_to(@user, :sid=)
  end

  test "status accessor for User class" do
    assert_respond_to(@user, :status)
    assert_respond_to(@user, :status=)
  end

  test "disabled accessor for User class" do
    assert_respond_to(@user, :disabled?)
    assert_respond_to(@user, :disabled=)
  end

  test "local accessor for User class" do
    assert_respond_to(@user, :local?)
    assert_respond_to(@user, :local=)
  end

  test "lockout accessor for User class" do
    assert_respond_to(@user, :lockout?)
    assert_respond_to(@user, :lockout=)
  end

  test "password_changeable accessor for User class" do
    assert_respond_to(@user, :password_changeable?)
    assert_respond_to(@user, :password_changeable=)
  end

  test "password_expires accessor for User class" do
    assert_respond_to(@user, :password_expires?)
    assert_respond_to(@user, :password_expires=)
  end

  test "password_required accessor for User class" do
    assert_respond_to(@user, :password_required?)
    assert_respond_to(@user, :password_required=)
  end

  test "account_type accessor for User class" do
    assert_respond_to(@user, :account_type)
    assert_respond_to(@user, :account_type=)
  end

  test "uid accessor for User class" do
    assert_respond_to(@user, :uid)
    assert_respond_to(@user, :uid=)
  end

  test "dir accessor for User class" do
    assert_respond_to(@user, :dir)
    assert_respond_to(@user, :dir=)
  end

  test "dir method returns either a string or nil" do
    assert_nothing_raised{ @user = Admin.get_user(@user_name, :localaccount => true) }
    assert_kind_of([String, NilClass], @user.dir)
  end

  # Group class

  test "caption accessor for Group class" do
    assert_respond_to(@group, :caption)
    assert_respond_to(@group, :caption=)
  end

  test "description accessor for Group class" do
    assert_respond_to(@group, :description)
    assert_respond_to(@group, :description=)
  end

  test "domain accessor for Group class" do
    assert_respond_to(@group, :domain)
    assert_respond_to(@group, :domain=)
  end

  test "install_date accessor for Group class" do
    assert_respond_to(@group, :install_date)
    assert_respond_to(@group, :install_date=)
  end

  test "name accessor for Group class" do
    assert_respond_to(@group, :name)
    assert_respond_to(@group, :name)
  end

  test "gid accessor for Group class" do
    assert_respond_to(@group, :gid)
    assert_respond_to(@group, :gid=)
  end

  test "status accessor for Group class" do
    assert_respond_to(@group, :status)
    assert_respond_to(@group, :status=)
  end

  test "sid accessor for Group class" do
    assert_respond_to(@group, :sid)
    assert_respond_to(@group, :sid=)
  end

  test "sid_type accessor for Group class" do
    assert_respond_to(@group, :sid_type)
    assert_respond_to(@group, :sid_type=)
  end

  test "local accessor for Group class" do
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
    @@elevated = nil
  end
end
