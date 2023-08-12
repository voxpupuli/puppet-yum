# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'the dnf_module_stream provider' do
  it 'loads' do
    expect(Puppet::Type.type(:dnf_module_stream).provide(:dnf_module_stream)).not_to be_nil
  end
end
