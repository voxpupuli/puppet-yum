# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:dnf_module_stream) do
  it 'loads' do
    expect(described_class).not_to be_nil
  end

  it 'has parameter module' do
    expect(described_class.parameters).to include(:module)
  end

  it 'has property stream' do
    expect(described_class.properties.map(&:name)).to include(:stream)
  end
end
