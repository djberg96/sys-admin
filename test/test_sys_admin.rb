###############################################################################
# test_sys_admin.rb
#
# This exists mostly for the sake of the gemspec, so that it calls the right
# test suite based on the platform.
###############################################################################
require 'test-unit'

if File::ALT_SEPARATOR
  require 'test_sys_admin_windows'
else
  require 'test_sys_admin_unix'
end

class TC_Sys_Admin_All < Test::Unit::TestCase
  test "version is set to expected value" do
    assert_equal('1.6.0', Sys::Admin::VERSION)
  end
end
