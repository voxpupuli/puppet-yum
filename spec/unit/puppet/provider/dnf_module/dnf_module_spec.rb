# frozen_string_literal: true

require 'spec_helper'

dnf_module = Puppet::Type.type(:dnf_module).provide(:dnf_module)
RSpec.describe dnf_module do
  it 'loads' do
    expect(dnf_module).not_to be_nil
  end
end
