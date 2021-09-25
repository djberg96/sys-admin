require 'rspec'
require 'sys-admin'

RSpec.configure do |config|
  config.filter_run_excluding(:darwin) if Gem::Platform.local.os != 'darwin'
  config.filter_run_excluding(:windows) unless Gem.win_platform?
  config.filter_run_excluding(:unix) if Gem.win_platform?
end
