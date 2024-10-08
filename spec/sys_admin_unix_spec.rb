# frozen_string_literal: true

###############################################################################
# sys_admin_unix_rspec.rb
#
# Test suite for the Unix version of sys-admin. This test should be run
# via the 'rake spec' task.
###############################################################################
require 'spec_helper'

RSpec.describe Sys::Admin, :unix do
  let(:user)     { 'nobody' }
  let(:user_id)  { 0 }
  let(:group)    { 'sys' }
  let(:group_id) { 3 }

  context 'singleton methods' do
    describe 'get_login' do
      example 'get_login basic functionality' do
        expect(described_class).to respond_to(:get_login)
        expect{ described_class.get_login }.not_to raise_error
      end

      example 'get_login returns a string' do
        expect(described_class.get_login).to be_a(String)
        expect(described_class.get_login.length).to be > 0
      end
    end

    describe 'get_user' do
      example 'get_user basic functionality' do
        expect(described_class).to respond_to(:get_user)
        expect{ described_class.get_user(user) }.not_to raise_error
        expect{ described_class.get_user(user_id) }.not_to raise_error
      end

      example 'get_user with a string argument works as expected' do
        expect(described_class.get_user(user)).to be_a(Sys::Admin::User)
      end

      example 'get_user with an integer argument works as expected' do
        expect(described_class.get_user(user_id)).to be_a(Sys::Admin::User)
      end

      example 'get_user requires at least one argument' do
        expect{ described_class.get_user }.to raise_error(ArgumentError)
      end

      example 'get_user requires a string or integer argument' do
        expect{ described_class.get_user([]) }.to raise_error(TypeError)
      end

      example 'get_user raises an Error if the user cannot be found' do
        expect{ described_class.get_user('foofoofoo') }.to raise_error(Sys::Admin::Error)
      end
    end

    describe 'users' do
      example 'users basic functionality' do
        expect(described_class).to respond_to(:users)
        expect{ described_class.users }.not_to raise_error
      end

      example 'users returns an array of User objects' do
        users = described_class.users
        expect(users).to be_a(Array)
        expect(users).to all(be_a(Sys::Admin::User))
      end

      example 'users accepts an optional lastlog argument on darwin', :darwin do
        users = described_class.users(:lastlog => false)
        expect(users).to be_a(Array)
        expect(users).to all(be_a(Sys::Admin::User))
        expect(users.first.login_time).to be_nil
      end
    end

    describe 'get_group' do
      before do
        described_class.class_eval do
          public :getgrgid_r
        end
      end

      example 'get_group basic functionality' do
        expect(described_class).to respond_to(:get_group)
        expect{ described_class.get_group(group) }.not_to raise_error
        expect{ described_class.get_group(group_id) }.not_to raise_error
      end

      example 'get_group accepts a string argument' do
        expect(described_class.get_group(group)).to be_a(Sys::Admin::Group)
      end

      example 'get_group accepts an integer argument' do
        expect(described_class.get_group(group_id)).to be_a(Sys::Admin::Group)
      end

      example 'get_group requires one argument only' do
        expect{ described_class.get_group }.to raise_error(ArgumentError)
        expect{ described_class.get_group(group_id, group_id) }.to raise_error(ArgumentError)
      end

      example 'get_group raises a TypeError if an invalid type is passed' do
        expect{ described_class.get_group([]) }.to raise_error(TypeError)
      end

      example 'get_group raises an Error if the group cannot be found' do
        expect{ described_class.get_group(123456789) }.to raise_error(Sys::Admin::Error)
        expect{ described_class.get_group('foofoofoo') }.to raise_error(Sys::Admin::Error)
      end

      example 'get_group handles large groups and will retry an ERANGE' do
        allow(described_class).to receive(:getgrgid_r).with(any_args).and_return(34)
        allow(described_class).to receive(:getgrgid_r).with(any_args).and_call_original
        expect{ described_class.get_group(group_id) }.not_to raise_error
      end

      example 'get_group will raise the expected error for an ENOENT' do
        allow(described_class).to receive(:getgrgid_r).with(any_args).and_return(2)
        expect{ described_class.get_group(group_id) }.to raise_error(Sys::Admin::Error)
      end

      example 'get_group will raise the expected error for a failed getgrxxx function call' do
        allow(described_class).to receive(:getgrgid_r).with(any_args).and_return(22)
        allow_any_instance_of(FFI::MemoryPointer).to receive(:null?).and_return(true)
        expect{ described_class.get_group(group_id) }.to raise_error(Errno::EINVAL)
      end

      example 'get_group will not retry failures other than an ERANGE' do
        allow(described_class).to receive(:getgrgid_r).with(any_args).and_return(35)
        expect{ described_class.get_group(group_id) }.to raise_error(Sys::Admin::Error)
      end
    end

    describe 'groups' do
      example 'groups basic functionality' do
        expect(described_class).to respond_to(:groups)
        expect{ described_class.groups }.not_to raise_error
      end

      example 'groups returns an array of Group objects' do
        groups = described_class.groups
        expect(groups).to be_a(Array)
        expect(groups).to all(be_a(Sys::Admin::Group))
      end

      example 'groups method does not accept any arguments' do
        expect{ described_class.groups(group_id) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'instance methods' do
    describe 'User instance methods' do
      example 'user.name behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:name)
        expect(user.name).to be_a(String)
      end

      example 'user.passwd behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:passwd)
        expect(user.passwd).to be_a(String)
      end

      example 'user.uid behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:uid)
        expect(user.uid).to be_a(Integer)
      end

      example 'user.gid behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:gid)
        expect(user.gid).to be_a(Integer)
      end

      example 'user.dir behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:dir)
        expect(user.dir).to be_a(String)
      end

      example 'user.shell behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:shell)
        expect(user.shell).to be_a(String)
      end

      example 'user.gecos behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:gecos)
        expect(user.gecos).to be_a(String).or be_nil
      end

      example 'user.quota behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:quota)
        expect(user.quota).to be_a(Integer).or be_nil
      end

      example 'user.age behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:age)
        expect(user.age).to be_a(Integer).or be_nil
      end

      example 'user.access behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:access_class)
        expect(user.access_class).to be_a(String).or be_nil
      end

      example 'user.comment behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:comment)
        expect(user.comment).to be_a(String).or be_nil
      end

      example 'user.expire behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:expire)
        expect(user.expire).to be_a(Time).or be_nil
      end

      example 'user.change behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:change)
        expect(user.change).to be_a(Time).or be_nil
      end

      example 'user.login_time behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:login_time)
        expect(user.login_time).to be_a(Time).or be_nil
      end

      example 'user.login_device behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:login_device)
        expect(user.login_device).to be_a(String).or be_nil
      end

      example 'user.login_host behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:login_host)
        expect(user.login_host).to be_a(String).or be_nil
      end

      example 'user.groups behaves as expected' do
        user = described_class.get_user(user_id)
        expect(user).to respond_to(:groups)
        expect(user.groups).to be_a(Array)
      end
    end

    describe 'Group instance methods' do
      example 'group.name behaves as expected' do
        group = described_class.get_group(group_id)
        expect(group).to respond_to(:name)
        expect(group.name).to be_a(String)
      end

      example 'group.gid behaves as expected' do
        group = described_class.get_group(group_id)
        expect(group).to respond_to(:gid)
        expect(group.gid).to be_a(Integer)
      end

      example 'group.members behaves as expected' do
        group = described_class.get_group(group_id)
        expect(group).to respond_to(:members)
        expect(group.members).to be_a(Array)
      end

      example 'group.passwd behaves as expected' do
        group = described_class.get_group(group_id)
        expect(group).to respond_to(:passwd)
        expect(group.passwd).to be_a(String)
      end
    end
  end

  context 'ffi functions' do
    example 'ffi functions are private' do
      methods = described_class.methods(false).map(&:to_s)
      expect(methods).not_to include('getlogin')
      expect(methods).not_to include('getlogin_r')
      expect(methods).not_to include('strerror')
    end
  end
end
