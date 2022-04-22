# frozen_string_literal: true

require 'rspec'
require 'sys-admin'

RSpec.configure do |config|
  config.filter_run_excluding(:darwin) if Gem::Platform.local.os != 'darwin'
  config.filter_run_excluding(:windows) unless Gem.win_platform?

  if Gem.win_platform?
    require 'win32-security'
    require 'socket'

    config.filter_run_excluding(:unix)

    config.before(:each, :requires_elevated => true) do
      skip 'skipped unless administrator privileges' unless Win32::Security.elevated_security?
    end
  end
end
