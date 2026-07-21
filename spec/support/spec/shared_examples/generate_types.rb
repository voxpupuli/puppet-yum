# frozen_string_literal: true

require 'puppet/generate/models/type/type'

RSpec.shared_examples 'a type that works with `puppet generate types`' do
  it 'does not raise an error' do
    expect { Puppet::Generate::Models::Type::Type.new(described_class) }.not_to raise_error
  end
end
