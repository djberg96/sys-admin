# frozen_string_literal: true

require 'rspec'
require 'sys-admin'

RSpec.configure do |config|
  config.filter_run_excluding(:darwin) if Gem::Platform.local.os != 'darwin'
  config.filter_run_excluding(:windows) unless Gem.win_platform?

  if Gem.win_platform?
    config.filter_run_excluding(:unix)
    require 'win32-security'
    require 'socket'
  end
end
