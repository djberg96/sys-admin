###############################################################################
# sys_admin_windows_spec.rb
#
# Test suite for the MS Windows version of sys-admin. Note that some of the
# are ordered. That way I can add test users before configuring or deleting
# them.
#
# It is assumed that these specs will be run via the 'rake spec' task.
###############################################################################
require 'rspec'
require 'sys/admin'
require 'win32/security'
require 'socket'

RSpec.describe Sys_Admin, :windows do
  let(host) { Socket.gethostname }
  let(elevated) { Win32::Security.elevated_security? }

  before do
    @user       = User.new
    @user_name  = 'Guest'
    @user_id    = 501        # best guess, may fail
    @group      = Group.new
    @group_name = 'Guests'
    @group_id   = 546        # best guess, may fail
  end

=begin
  # Admin singleton methods

  def test_01_add_user
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:add_user)
    assert_nothing_raised{
      Admin.add_user(:name => 'foo', :password => 'a1b2c3D4')
    }
  end

  def test_02_config_user
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:configure_user)
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
    expect(Admin).to respond_to(:delete_user)
    expect{ Admin.delete_user('foo') }.not_to raise_error
  end

  def test_01_add_group
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:add_group)
    expect{ Admin.add_group(:name => 'bar') }.not_to raise_error
  end

  def test_02_configure_group
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:configure_group)
    assert_nothing_raised{
      Admin.configure_group(:name => 'bar', :description => 'delete me')
    }
  end

  def test_03_add_group_member
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:add_group_member)
    expect{ Admin.add_group_member('foo', 'bar') }.not_to raise_error
  end

  def test_04_remove_group_member
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:remove_group_member)
    expect{ Admin.remove_group_member('foo', 'bar') }.not_to raise_error
  end

  def test_05_delete_group
    omit_unless(@@elevated)
    expect(Admin).to respond_to(:delete_group)
    expect{ Admin.delete_group('bar') }.not_to raise_error
  end
=end

  example "get_login basic functionality" do
    expect(Admin).to respond_to(:get_login)
    expect{ Admin.get_login }.not_to raise_error
  end

  example "get_login returns a string" do
    expect( Admin.get_login).to be_kind_of(String)
    expect(Admin.get_login.size > 0).to be_true
  end

  example "get_login does not accept any arguments" do
    expect{ Admin.get_login('foo') }.to raise_error(ArgumentError)
  end

  example "get_user basic functionality" do
    expect(Admin).to respond_to(:get_user)
  end

  example "get_user with string argument works as expected" do
    expect{ Admin.get_user(@user_name, :localaccount => true) }.not_to raise_error
    expect( :localaccount => true)).to be_kind_of(User, Admin.get_user(@user_name)
  end

  example "get user with integer argument works as expected" do
    expect{ Admin.get_user(@user_id, :localaccount => true) }.not_to raise_error
    expect( :localaccount => true)).to be_kind_of(User, Admin.get_user(@user_id)
  end

  example "get_user method by string accepts a hash of options" do
    options = {:host => @@host, :localaccount => true}
    expect{ Admin.get_user(@user_name, options) }.not_to raise_error
    expect( options)).to be_kind_of(User, Admin.get_user(@user_name)
  end

  example "get_user method by uid accepts a hash of options" do
    options = {:host => @@host, :localaccount => true}
    expect{ Admin.get_user(@user_id, options) }.not_to raise_error
    expect( options)).to be_kind_of(User, Admin.get_user(@user_id)
  end

  example "get_user method requires an argument" do
    assert_raises(ArgumentError){ Admin.get_user }
  end

  example "users method basic functionality" do
    expect(Admin).to respond_to(:users)
    expect{ Admin.users(:localaccount => true) }.not_to raise_error
  end

  example "users method returns an array of User objects" do
    expect( Admin.users(:localaccount => true)).to be_kind_of(Array)
    expect( Admin.users(:localaccount => true).first).to be_kind_of(User)
  end

  example "get_group basic functionality" do
    expect(Admin).to respond_to(:get_group)
  end

  example "get_group method returns expected results with a string argument" do
    expect{ Admin.get_group(@group_name, :localaccount => true) }.not_to raise_error
    expect( :localaccount => true)).to be_kind_of(Group, Admin.get_group(@group_name)
  end

  example "get_group method returns expected results with an integer argument" do
    expect{ Admin.get_group(@group_id, :localaccount => true) }.not_to raise_error
    expect( :localaccount => true)).to be_kind_of(Group, Admin.get_group(@group_id)
  end

  # TODO: Update
  example "get_group method accepts a hash of options" do
    expect{ Admin.get_group(@group_name, :localaccount => true) }.not_to raise_error
    expect( :localaccount => true)).to be_kind_of(Group, Admin.get_group(@group_name)
  end

  example "get_group method requires an argument" do
    expect{ Admin.get_group }.to raise_error(ArgumentError)
  end

  example "get_groups method basic functionality" do
    expect(Admin).to respond_to(:groups)
    expect{ Admin.groups(:localaccount => true) }.not_to raise_error
  end

  example "get_groups method returns an array of Group objects" do
    expect( Admin.groups(:localaccount => true)).to be_kind_of(Array)
    expect( Admin.groups(:localaccount => true).first).to be_kind_of(Group)
  end

  # User class

  example "caption accessor for User class" do
    expect(@user).to respond_to(:caption)
    expect(@user).to respond_to(:caption=)
  end

  example "description accessor for User class" do
    expect(@user).to respond_to(:description)
    expect(@user).to respond_to(:description=)
  end

  example "domain accessor for User class" do
    expect(@user).to respond_to(:domain)
    expect(@user).to respond_to(:domain=)
  end

  example "password accessor for User class" do
    expect(@user).to respond_to(:password)
    expect(@user).to respond_to(:password=)
  end

  example "full_name accessor for User class" do
    expect(@user).to respond_to(:full_name)
    expect(@user).to respond_to(:full_name=)
  end

  example "name accessor for User class" do
    expect(@user).to respond_to(:name)
    expect(@user).to respond_to(:name=)
  end

  example "sid accessor for User class" do
    expect(@user).to respond_to(:sid)
    expect(@user).to respond_to(:sid=)
  end

  example "status accessor for User class" do
    expect(@user).to respond_to(:status)
    expect(@user).to respond_to(:status=)
  end

  example "disabled accessor for User class" do
    expect(@user).to respond_to(:disabled?)
    expect(@user).to respond_to(:disabled=)
  end

  example "local accessor for User class" do
    expect(@user).to respond_to(:local?)
    expect(@user).to respond_to(:local=)
  end

  example "lockout accessor for User class" do
    expect(@user).to respond_to(:lockout?)
    expect(@user).to respond_to(:lockout=)
  end

  example "password_changeable accessor for User class" do
    expect(@user).to respond_to(:password_changeable?)
    expect(@user).to respond_to(:password_changeable=)
  end

  example "password_expires accessor for User class" do
    expect(@user).to respond_to(:password_expires?)
    expect(@user).to respond_to(:password_expires=)
  end

  example "password_required accessor for User class" do
    expect(@user).to respond_to(:password_required?)
    expect(@user).to respond_to(:password_required=)
  end

  example "account_type accessor for User class" do
    expect(@user).to respond_to(:account_type)
    expect(@user).to respond_to(:account_type=)
  end

  example "uid accessor for User class" do
    expect(@user).to respond_to(:uid)
    expect(@user).to respond_to(:uid=)
  end

  example "dir accessor for User class" do
    expect(@user).to respond_to(:dir)
    expect(@user).to respond_to(:dir=)
  end

  example "dir method returns either a string or nil" do
    expect{ @user = Admin.get_user(@user_name, :localaccount => true) }.not_to raise_error
    expect( @user.dir).to be_kind_of([String, NilClass])
  end

  # Group class

  example "caption accessor for Group class" do
    expect(@group).to respond_to(:caption)
    expect(@group).to respond_to(:caption=)
  end

  example "description accessor for Group class" do
    expect(@group).to respond_to(:description)
    expect(@group).to respond_to(:description=)
  end

  example "domain accessor for Group class" do
    expect(@group).to respond_to(:domain)
    expect(@group).to respond_to(:domain=)
  end

  example "install_date accessor for Group class" do
    expect(@group).to respond_to(:install_date)
    expect(@group).to respond_to(:install_date=)
  end

  example "name accessor for Group class" do
    expect(@group).to respond_to(:name)
    expect(@group).to respond_to(:name)
  end

  example "gid accessor for Group class" do
    expect(@group).to respond_to(:gid)
    expect(@group).to respond_to(:gid=)
  end

  example "status accessor for Group class" do
    expect(@group).to respond_to(:status)
    expect(@group).to respond_to(:status=)
  end

  example "sid accessor for Group class" do
    expect(@group).to respond_to(:sid)
    expect(@group).to respond_to(:sid=)
  end

  example "sid_type accessor for Group class" do
    expect(@group).to respond_to(:sid_type)
    expect(@group).to respond_to(:sid_type=)
  end

  example "local accessor for Group class" do
    expect(@group).to respond_to(:local?)
    expect(@group).to respond_to(:local=)
  end
end
