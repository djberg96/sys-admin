require 'spec_helper'

RSpec.describe Sys::Admin do
  example "version is set to expected value" do
    expect(described_class::VERSION).to eq('1.8.0')
  end

  example "version constant is frozen" do
    expect(described_class::VERSION).to be_frozen
  end
end
