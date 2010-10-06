###############################################################################
# test_sys_admin_unix.rb
#
# Test suite for the Unix version of sys-admin. This test should be run
# via the 'rake test' task.
###############################################################################
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

  def test_get_login
    assert_respond_to(Admin, :get_login)
    assert_nothing_raised{ Admin.get_login }
    assert_kind_of(String, Admin.get_login)
  end

  def test_get_user_basic
    assert_respond_to(Admin, :get_user)
    assert_nothing_raised{ Admin.get_user(@user) }
    assert_nothing_raised{ Admin.get_user(@user_id) }
  end

  def test_get_user_by_name
    assert_kind_of(User, Admin.get_user(@user))
  end

  def test_get_user_by_id
    assert_kind_of(User, Admin.get_user(@user_id))
  end

  def test_get_user_expected_errors
    assert_raise(ArgumentError){ Admin.get_user }
    assert_raise(TypeError){ Admin.get_user([]) }
    assert_raise(Admin::Error){ Admin.get_user('foofoofoo') }
  end

  def test_users_basic
    assert_respond_to(Admin, :users)
    assert_nothing_raised{ Admin.users }
  end

  def test_users
    assert_kind_of(Array, Admin.users)
    assert_kind_of(User, Admin.users.first)
  end

  def test_users_block_form
    array = []
    assert_nothing_raised{ Admin.users{ |g| array << g } }
    assert_equal(true, Admin.users.length == array.length)
    assert_nothing_raised{ Admin.users{ |g| break } }
  end

  def test_users_expected_errors
    assert_raise(ArgumentError){ Admin.users(@user_id) }
  end

  def test_get_group_basic
    assert_respond_to(Admin, :get_group)
    assert_nothing_raised{ Admin.get_group(@group) }
    assert_nothing_raised{ Admin.get_group(@group_id) }
  end

  def test_get_group_by_name
    assert_kind_of(Group, Admin.get_group(@group))
  end

  def test_get_group_by_id
    assert_kind_of(Group, Admin.get_group(@group_id))
  end

  def test_get_group_expected_errors
    assert_raise(ArgumentError){ Admin.get_group }
    assert_raise(TypeError){ Admin.get_group([]) }
    assert_raise(Admin::Error){ Admin.get_group('foofoofoo') }
  end

  def test_groups_basic
    assert_respond_to(Admin, :groups)
    assert_nothing_raised{ Admin.groups }
  end

  def test_groups
    assert_kind_of(Array, Admin.groups)
    assert_kind_of(Group, Admin.groups.first)
  end

  def test_groups_expected_errors
    assert_raise(ArgumentError){ Admin.groups(@group_id) }
  end

  def test_groups_block_form
    array = []
    assert_nothing_raised{ Admin.groups{ |g| array << g } }
    assert_equal(true, Admin.groups.length == array.length)
    assert_nothing_raised{ Admin.groups{ |g| break } }
  end

  ## User Tests

  def test_user_name
    @user = Admin.users.first
    assert_respond_to(@user, :name)
    assert_kind_of(String, @user.name)
  end

  def test_user_passwd
    @user = Admin.users.first
    assert_respond_to(@user, :passwd)
    assert_kind_of(String, @user.passwd)
  end

  def test_user_uid
    @user = Admin.users.first
    assert_respond_to(@user, :uid)
    assert_kind_of(Fixnum, @user.uid)
  end

  def test_user_gid
    @user = Admin.users.first
    assert_respond_to(@user, :gid)
    assert_kind_of(Fixnum, @user.gid)
  end

  def test_user_dir
    @user = Admin.users.first
    assert_respond_to(@user, :dir)
    assert_kind_of(String, @user.dir)
  end

  def test_user_shell
    @user = Admin.users.first
    assert_respond_to(@user, :shell)
    assert_kind_of(String, @user.shell)
  end

  def test_user_gecos
    @user = Admin.users.first
    assert_respond_to(@user, :gecos)
    assert_kind_of(String, @user.gecos)
  end

  def test_user_quota
    @user = Admin.users.first
    assert_respond_to(@user, :quota)
    assert_true([Fixnum, NilClass].include?(@user.quota.class))
  end

  def test_user_age
    @user = Admin.users.first
    assert_respond_to(@user, :age)
    assert_true([Fixnum, NilClass].include?(@user.age.class))
  end

  def test_user_access_class
    @user = Admin.users.first
    assert_respond_to(@user, :access_class)
    assert_true([String, NilClass].include?(@user.access_class.class))
  end

  def test_user_comment
    @user = Admin.users.first
    assert_respond_to(@user, :comment)
    assert_true([String, NilClass].include?(@user.comment.class))
  end

  def test_user_expire
    @user = Admin.users.first
    assert_respond_to(@user, :expire)
    assert_true([Time, NilClass].include?(@user.expire.class))
  end

  def test_user_change
    @user = Admin.users.first
    assert_respond_to(@user, :change)
    assert_true([Time, NilClass].include?(@user.change.class))
  end

  def test_user_login_time
    @user = Admin.users.first
    assert_respond_to(@user, :login_time)
    assert_true([Time, NilClass].include?(@user.login_time.class))
  end

  def test_user_login_device
    @user = Admin.users.first
    assert_respond_to(@user, :login_device)
    assert_true([String, NilClass].include?(@user.login_device.class))
  end

  def test_user_login_host
    @user = Admin.users.first
    assert_respond_to(@user, :login_host)
    assert_true([String, NilClass].include?(@user.login_host.class))
  end

  def test_user_groups
    @user = Admin.users.first
    assert_respond_to(@user, :groups)
    assert_kind_of(Array, @user.groups)
  end

  ## Group Tests

  def test_group_name
    @group = Admin.groups.first
    assert_respond_to(@group, :name)
    assert_kind_of(String, @group.name)
  end

  def test_group_gid
    @group = Admin.groups.first
    assert_respond_to(@group, :gid)
    assert_kind_of(Fixnum, @group.gid)
  end

  def test_group_members
    @group = Admin.groups.first
    assert_respond_to(@group, :members)
    assert_kind_of(Array, @group.members)
  end

  def test_group_passwd
    @group = Admin.groups.first
    assert_respond_to(@group, :passwd)
    assert_kind_of(String, @group.passwd)
  end

  def teardown
    @user     = nil
    @user_id  = nil
    @group    = nil
    @group_id = nil
  end
end
