###############################################################################
# test_sys_admin_unix.rb
#
# Test suite for the Unix version of sys-admin. This test should be run
# via the 'rake test' task.
###############################################################################
require 'rubygems'
gem 'test-unit'
require 'test/unit'
require 'sys/admin'
include Sys

class TC_Sys_Admin_Unix < Test::Unit::TestCase
  def setup
    @user     = 'nobody'
    @user_id  = 0
    @group    = 'sys'
    @group_id = 3
  end

  ## Admin singleton methods

  test "get_login basic functionality" do
    assert_respond_to(Admin, :get_login)
    assert_nothing_raised{ Admin.get_login }
  end

  test "get_login returns a string" do
    assert_kind_of(String, Admin.get_login)
    assert_true(Admin.get_login.length > 0)
  end

  test "get_user basic functionality" do
    assert_respond_to(Admin, :get_user)
    assert_nothing_raised{ Admin.get_user(@user) }
    assert_nothing_raised{ Admin.get_user(@user_id) }
  end

  test "get_user with a string argument works as expected" do
    assert_kind_of(Admin::User, Admin.get_user(@user))
  end

  test "get_user with an integer argument works as expected" do
    assert_kind_of(Admin::User, Admin.get_user(@user_id))
  end

  test "get_user requires one argument only" do
    assert_raise(ArgumentError){ Admin.get_user }
    assert_raise(ArgumentError){ Admin.get_user(@user, @user) }
  end

  test "get_user requires a string or integer argument" do
    assert_raise(TypeError){ Admin.get_user([]) }
  end

  test "get_user raises an Error if the user cannot be found" do
    assert_raise(Admin::Error){ Admin.get_user('foofoofoo') }
  end

  test "users basic functionality" do
    assert_respond_to(Admin, :users)
    assert_nothing_raised{ Admin.users }
  end

  test "users returns an array of User objects" do
    users = Admin.users
    assert_kind_of(Array, users)
    assert_kind_of(Admin::User, users.first)
  end

  test "users does not accept any arguments" do
    assert_raise(ArgumentError){ Admin.users(@user_id) }
  end

  test "get_group basic functionality" do
    assert_respond_to(Admin, :get_group)
    assert_nothing_raised{ Admin.get_group(@group) }
    assert_nothing_raised{ Admin.get_group(@group_id) }
  end

  test "get_group accepts a string argument" do
    assert_kind_of(Admin::Group, Admin.get_group(@group))
  end

  test "get_group accepts an integer argument" do
    assert_kind_of(Admin::Group, Admin.get_group(@group_id))
  end

  test "get_group requires one argument only" do
    assert_raise(ArgumentError){ Admin.get_group }
    assert_raise(ArgumentError){ Admin.get_group(@group_id, @group_id) }
  end

  test "get_group raises a TypeError if an invalid type is passed" do
    assert_raise(TypeError){ Admin.get_group([]) }
  end

  test "get_group raises an Error if the group cannot be found" do
    assert_raise(Admin::Error){ Admin.get_group('foofoofoo') }
  end

  test "groups basic functionality" do
    assert_respond_to(Admin, :groups)
    assert_nothing_raised{ Admin.groups }
  end

  test "groups returns an array of Group objects" do
    groups = Admin.groups
    assert_kind_of(Array, groups)
    assert_kind_of(Admin::Group, groups.first)
  end

  test "groups method does not accept any arguments" do
    assert_raise(ArgumentError){ Admin.groups(@group_id) }
  end

  ## User Tests

  test "user.name behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :name)
    assert_kind_of(String, @user.name)
  end

  test "user.passwd behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :passwd)
    assert_kind_of(String, @user.passwd)
  end

  test "user.uid behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :uid)
    assert_kind_of(Fixnum, @user.uid)
  end

  test "user.gid behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :gid)
    assert_kind_of(Fixnum, @user.gid)
  end

  test "user.dir behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :dir)
    assert_kind_of(String, @user.dir)
  end

  test "user.shell behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :shell)
    assert_kind_of(String, @user.shell)
  end

  test "user.gecos behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :gecos)
    assert_kind_of(String, @user.gecos)
  end

  test "user.quota behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :quota)
    assert_true([Fixnum, NilClass].include?(@user.quota.class))
  end

  test "user.age behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :age)
    assert_true([Fixnum, NilClass].include?(@user.age.class))
  end

  test "user.access behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :access_class)
    assert_true([String, NilClass].include?(@user.access_class.class))
  end

  test "user.comment behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :comment)
    assert_true([String, NilClass].include?(@user.comment.class))
  end

  test "user.expire behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :expire)
    assert_true([Time, NilClass].include?(@user.expire.class))
  end

  test "user.change behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :change)
    assert_true([Time, NilClass].include?(@user.change.class))
  end

  test "user.login_time behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :login_time)
    assert_true([Time, NilClass].include?(@user.login_time.class))
  end

  test "user.login_device behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :login_device)
    assert_true([String, NilClass].include?(@user.login_device.class))
  end

  test "user.login_host behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :login_host)
    assert_true([String, NilClass].include?(@user.login_host.class))
  end

  test "user.groups behaves as expected" do
    @user = Admin.get_user(@user_id)
    assert_respond_to(@user, :groups)
    assert_kind_of(Array, @user.groups)
  end

  ## Group Tests

  test "group.name behaves as expected" do
    @group = Admin.get_group(@group_id)
    assert_respond_to(@group, :name)
    assert_kind_of(String, @group.name)
  end

  test "group.gid behaves as expected" do
    @group = Admin.get_group(@group_id)
    assert_respond_to(@group, :gid)
    assert_kind_of(Fixnum, @group.gid)
  end

  test "group.members behaves as expected" do
    @group = Admin.get_group(@group_id)
    assert_respond_to(@group, :members)
    assert_kind_of(Array, @group.members)
  end

  test "group.passwd behaves as expected" do
    @group = Admin.get_group(@group_id)
    assert_respond_to(@group, :passwd)
    assert_kind_of(String, @group.passwd)
  end

  ## FFI

  test "ffi functions are private" do
    methods = Admin.methods(false).map{ |e| e.to_s }
    assert_false(Admin.methods.include?('getlogin'))
    assert_false(Admin.methods.include?('getlogin_r'))
    assert_false(Admin.methods.include?('strerror'))
  end

  def teardown
    @user     = nil
    @user_id  = nil
    @group    = nil
    @group_id = nil
 end
end
