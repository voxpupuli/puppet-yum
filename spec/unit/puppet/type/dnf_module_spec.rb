# frozen_string_literal: true

require 'spec_helper'

dnf_module = Puppet::Type.type(:dnf_module)
RSpec.describe 'the dnf_module type' do
  let :params do
    %i[title module]
  end

  it 'loads' do
    expect(dnf_module).not_to be_nil
  end

  it 'has expected parameters' do
    params.each do |param|
      expect(dnf_module.parameters).to be_include(param)
    end
  end
end
