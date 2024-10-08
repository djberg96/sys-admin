# frozen_string_literal: true

###############################################################################
# sys_admin_windows_spec.rb
#
# Test suite for the MS Windows version of sys-admin. Note that some of the
# are ordered. That way I can add test users before configuring or deleting
# them. These tests require admin privileges, otherwise they are skipped.
#
# It is assumed that these specs will be run via the 'rake spec' task.
###############################################################################
require 'spec_helper'

RSpec.describe Sys::Admin, :windows do
  let(:host) { Socket.gethostname }

  before do
    @user       = Sys::Admin::User.new
    @user_name  = 'Guest'
    @user_id    = 501        # best guess, may fail
    @group      = Sys::Admin::Group.new
    @group_name = 'Guests'
    @group_id   = 546        # best guess, may fail
  end

  describe 'add, configure and delete user', :requires_elevated, :order => :defined do
    before(:all) do
      @local_user = 'foo'
    end

    example 'add user' do
      expect(described_class).to respond_to(:add_user)
      expect{ described_class.add_user(:name => @local_user, :password => 'a1b2c3D4') }.not_to raise_error
      expect{ described_class.get_user(@local_user) }.not_to raise_error
    end

    example 'configure user' do
      expect(described_class).to respond_to(:configure_user)
      expect do
        described_class.configure_user(
          :name        => @local_user,
          :description => 'delete me',
          :fullname    => 'fubar',
          :password    => 'd1c2b3A4'
        )
      end.not_to raise_error
      expect(described_class.get_user(@local_user).description).to eq('delete me')
    end

    example 'delete user' do
      expect(described_class).to respond_to(:delete_user)
      expect{ described_class.delete_user(@local_user) }.not_to raise_error
      expect{ described_class.get_user(@local_user) }.to raise_error(Sys::Admin::Error)
    end
  end

  describe 'add, configure and delete group', :requires_elevated, :order => :defined do
    before(:all) do
      @local_user = 'foo'
      @local_group = 'bar'
      described_class.add_user(:name => @local_user) if Win32::Security.elevated_security?
    end

    after(:all) do
      described_class.delete_user(@local_user) if Win32::Security.elevated_security?
    end

    example 'add group' do
      expect(described_class).to respond_to(:add_group)
      expect{ described_class.add_group(:name => @local_group) }.not_to raise_error
    end

    example 'configure group' do
      expect(described_class).to respond_to(:configure_group)
      expect{ described_class.configure_group(:name => @local_group, :description => 'delete me') }.not_to raise_error
    end

    example 'add group member' do
      expect(described_class).to respond_to(:add_group_member)
      expect{ described_class.add_group_member(@local_user, @local_group) }.not_to raise_error
      expect(described_class.get_group(@local_group, :localaccount => true).members).to include(@local_user)
    end

    example 'remove group member' do
      expect(described_class).to respond_to(:remove_group_member)
      expect{ described_class.remove_group_member(@local_user, @local_group) }.not_to raise_error
    end

    example 'delete group' do
      expect(described_class).to respond_to(:delete_group)
      expect{ described_class.delete_group(@local_group) }.not_to raise_error
    end
  end

  context 'singleton methods' do
    describe 'get_login' do
      example 'get_login basic functionality' do
        expect(described_class).to respond_to(:get_login)
        expect{ described_class.get_login }.not_to raise_error
      end

      example 'get_login returns a string' do
        expect(described_class.get_login).to be_a(String)
        expect(described_class.get_login.size).to be > 0
      end

      example 'get_login does not accept any arguments' do
        expect{ described_class.get_login('foo') }.to raise_error(ArgumentError)
      end
    end

    describe 'get_user' do
      example 'get_user basic functionality' do
        expect(described_class).to respond_to(:get_user)
      end

      example 'get_user with string argument works as expected' do
        expect{ described_class.get_user(@user_name, :localaccount => true) }.not_to raise_error
        expect(described_class.get_user(@user_name, :localaccount => true)).to be_a(Sys::Admin::User)
      end

      example 'get user with integer argument works as expected' do
        expect{ described_class.get_user(@user_id, :localaccount => true) }.not_to raise_error
        expect(described_class.get_user(@user_id, :localaccount => true)).to be_a(Sys::Admin::User)
      end

      example 'get_user method by string accepts a hash of options' do
        options = {:host => host, :localaccount => true}
        expect{ described_class.get_user(@user_name, options) }.not_to raise_error
        expect(described_class.get_user(@user_name, options)).to be_a(Sys::Admin::User)
      end

      example 'get_user method by uid accepts a hash of options' do
        options = {:host => host, :localaccount => true}
        expect{ described_class.get_user(@user_id, options) }.not_to raise_error
        expect(described_class.get_user(@user_id, options)).to be_a(Sys::Admin::User)
      end

      example 'get_user method requires an argument' do
        expect{ described_class.get_user }.to raise_error(ArgumentError)
      end
    end

    describe 'users' do
      example 'users method basic functionality' do
        expect(described_class).to respond_to(:users)
        expect{ described_class.users(:localaccount => true) }.not_to raise_error
      end

      example 'users method returns an array of User objects' do
        users = described_class.users(:localaccount => true)
        expect(users).to be_a(Array)
        expect(users).to all(be_a(Sys::Admin::User))
      end
    end

    describe 'get_group' do
      example 'get_group basic functionality' do
        expect(described_class).to respond_to(:get_group)
      end

      example 'get_group method returns expected results with a string argument' do
        expect{ described_class.get_group(@group_name, :localaccount => true) }.not_to raise_error
        expect(described_class.get_group(@group_name, :localaccount => true)).to be_a(Sys::Admin::Group)
      end

      example 'get_group method returns expected results with an integer argument' do
        expect{ described_class.get_group(@group_id, :localaccount => true) }.not_to raise_error
        expect(described_class.get_group(@group_id, :localaccount => true)).to be_a(Sys::Admin::Group)
      end

      example 'get_group method accepts a hash of options' do
        options = {:host => host, :localaccount => true}
        expect{ described_class.get_group(@group_name, options) }.not_to raise_error
        expect(described_class.get_group(@group_name, options)).to be_a(Sys::Admin::Group)
      end

      example 'get_group method requires an argument' do
        expect{ described_class.get_group }.to raise_error(ArgumentError)
      end
    end

    describe 'groups' do
      example 'groups method basic functionality' do
        expect(described_class).to respond_to(:groups)
        expect{ described_class.groups(:localaccount => true) }.not_to raise_error
      end

      example 'groups method returns an array of Group objects' do
        groups = described_class.groups(:localaccount => true)
        expect(groups).to be_a(Array)
        expect(groups).to all(be_a(Sys::Admin::Group))
      end
    end
  end

  context 'User class' do
    example 'caption accessor for User class' do
      expect(@user).to respond_to(:caption)
      expect(@user).to respond_to(:caption=)
    end

    example 'description accessor for User class' do
      expect(@user).to respond_to(:description)
      expect(@user).to respond_to(:description=)
    end

    example 'domain accessor for User class' do
      expect(@user).to respond_to(:domain)
      expect(@user).to respond_to(:domain=)
    end

    example 'password accessor for User class' do
      expect(@user).to respond_to(:password)
      expect(@user).to respond_to(:password=)
    end

    example 'full_name accessor for User class' do
      expect(@user).to respond_to(:full_name)
      expect(@user).to respond_to(:full_name=)
    end

    example 'name accessor for User class' do
      expect(@user).to respond_to(:name)
      expect(@user).to respond_to(:name=)
    end

    example 'sid accessor for User class' do
      expect(@user).to respond_to(:sid)
      expect(@user).to respond_to(:sid=)
    end

    example 'status accessor for User class' do
      expect(@user).to respond_to(:status)
      expect(@user).to respond_to(:status=)
    end

    example 'disabled accessor for User class' do
      expect(@user).to respond_to(:disabled?)
      expect(@user).to respond_to(:disabled=)
    end

    example 'local accessor for User class' do
      expect(@user).to respond_to(:local?)
      expect(@user).to respond_to(:local=)
    end

    example 'lockout accessor for User class' do
      expect(@user).to respond_to(:lockout?)
      expect(@user).to respond_to(:lockout=)
    end

    example 'password_changeable accessor for User class' do
      expect(@user).to respond_to(:password_changeable?)
      expect(@user).to respond_to(:password_changeable=)
    end

    example 'password_expires accessor for User class' do
      expect(@user).to respond_to(:password_expires?)
      expect(@user).to respond_to(:password_expires=)
    end

    example 'password_required accessor for User class' do
      expect(@user).to respond_to(:password_required?)
      expect(@user).to respond_to(:password_required=)
    end

    example 'account_type accessor for User class' do
      expect(@user).to respond_to(:account_type)
      expect(@user).to respond_to(:account_type=)
    end

    example 'uid accessor for User class' do
      expect(@user).to respond_to(:uid)
      expect(@user).to respond_to(:uid=)
    end

    example 'dir accessor for User class' do
      expect(@user).to respond_to(:dir)
      expect(@user).to respond_to(:dir=)
    end

    example 'dir method returns either a string or nil' do
      expect{ @user = described_class.get_user(@user_name, :localaccount => true) }.not_to raise_error
      expect(@user.dir).to be_a(String).or be_a(NilClass)
    end
  end

  context 'Group class' do
    example 'caption accessor for Group class' do
      expect(@group).to respond_to(:caption)
      expect(@group).to respond_to(:caption=)
    end

    example 'description accessor for Group class' do
      expect(@group).to respond_to(:description)
      expect(@group).to respond_to(:description=)
    end

    example 'domain accessor for Group class' do
      expect(@group).to respond_to(:domain)
      expect(@group).to respond_to(:domain=)
    end

    example 'install_date accessor for Group class' do
      expect(@group).to respond_to(:install_date)
      expect(@group).to respond_to(:install_date=)
    end

    example 'name accessor for Group class' do
      expect(@group).to respond_to(:name)
      expect(@group).to respond_to(:name)
    end

    example 'gid accessor for Group class' do
      expect(@group).to respond_to(:gid)
      expect(@group).to respond_to(:gid=)
    end

    example 'status accessor for Group class' do
      expect(@group).to respond_to(:status)
      expect(@group).to respond_to(:status=)
    end

    example 'sid accessor for Group class' do
      expect(@group).to respond_to(:sid)
      expect(@group).to respond_to(:sid=)
    end

    example 'sid_type accessor for Group class' do
      expect(@group).to respond_to(:sid_type)
      expect(@group).to respond_to(:sid_type=)
    end

    example 'local accessor for Group class' do
      expect(@group).to respond_to(:local?)
      expect(@group).to respond_to(:local=)
    end
  end
end
