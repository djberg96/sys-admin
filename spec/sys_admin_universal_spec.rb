# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sys::Admin do
  example 'version is set to expected value' do
    expect(described_class::VERSION).to eq('1.8.1')
  end

  example 'version constant is frozen' do
    expect(described_class::VERSION).to be_frozen
  end

  example 'constructor is private' do
    expect{ described_class.new }.to raise_error(NoMethodError)
  end
end
