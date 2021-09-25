require 'rspec'

RSpec.configure do |config|
  config.filter_run_excluding(:darwin) if Gem::Platform.local.os != 'darwin'
end
