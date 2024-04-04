# frozen_string_literal: true

require 'spec_helper'

dnf_module_stream = Puppet::Type.type(:dnf_module_stream)
RSpec.describe 'the dnf_module_stream type' do
  it 'loads' do
    expect(dnf_module_stream).not_to be_nil
  end

  it 'has parameter module' do
    expect(dnf_module_stream.parameters).to be_include(:module)
  end

  it 'has property stream' do
    expect(dnf_module_stream.properties.map(&:name)).to be_include(:stream)
  end
end
