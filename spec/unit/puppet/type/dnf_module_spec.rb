# frozen_string_literal: true

require 'spec_helper'

dnf_module = Puppet::Type.type(:dnf_module)
RSpec.describe 'the dnf_module type' do
  let :params do
    %i[title module]
  end

  let :properties do
    %i[enabled_stream installed_profiles]
  end

  it 'loads' do
    expect(dnf_module).not_to be_nil
  end

  it 'has expected parameters' do
    params.each do |param|
      expect(dnf_module.parameters).to be_include(param)
    end
  end

  it 'has expected properties' do
    properties.each do |property|
      expect(dnf_module.properties.map(&:name)).to be_include(property)
    end
  end
end
