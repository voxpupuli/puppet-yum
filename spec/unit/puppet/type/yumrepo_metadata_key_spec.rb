# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../fixtures/modules/yumrepo_core/lib/puppet/type/yumrepo'

describe Puppet::Type.type(:yumrepo_metadata_key) do
  let(:resource_name) { 'baseos:21CB256AE16FC54C6E652949702D426D350D275D' }

  def new_resource(attributes = {})
    described_class.new({ name: resource_name }.merge(attributes))
  end

  it 'loads' do
    expect(described_class).not_to be_nil
  end

  describe 'namevars' do
    it 'has 3 namevars' do
      expect(described_class.key_attributes.size).to eq(3)
    end

    %i[name repo fingerprint].each do |param|
      it "'#{param}' is a namevar" do
        expect(described_class.key_attributes).to include(param)
      end
    end
  end

  describe 'ensure' do
    it 'is ensurable' do
      expect(described_class.attrtype(:ensure)).to eq(:property)
    end

    it 'accepts present' do
      expect(new_resource(ensure: :present)[:ensure]).to eq(:present)
    end

    it 'accepts absent' do
      expect(new_resource(ensure: :absent)[:ensure]).to eq(:absent)
    end

    it 'rejects other values' do
      expect { new_resource(ensure: :installed) }.to raise_error(%r{Invalid value :installed\. Valid values are present, absent})
    end
  end

  describe 'title' do
    it 'is rejected without a 40-character fingerprint' do
      expect { described_class.new(name: 'baseos:nothex') }.to raise_error(%r{No set of title patterns matched})
    end
  end

  describe 'repo' do
    it 'is set from resource title' do
      expect(new_resource[:repo]).to eq('baseos')
    end
  end

  describe 'fingerprint' do
    it 'is set from resource title' do
      expect(new_resource[:fingerprint]).to eq('21CB256AE16FC54C6E652949702D426D350D275D')
    end

    it 'is upcased' do
      expect(described_class.new(name: 'baseos:21cb256ae16fc54c6e652949702d426d350d275d')[:fingerprint]).to eq('21CB256AE16FC54C6E652949702D426D350D275D')
    end
  end

  describe 'content' do
    it 'is a property' do
      expect(described_class.attrtype(:content)).to eq(:property)
    end

    it 'accepts an armored key string' do
      expect(new_resource(content: 'ARMORED KEY')[:content]).to eq('ARMORED KEY')
    end
  end

  describe 'autorequire' do
    let(:catalog) { Puppet::Resource::Catalog.new }
    let(:repo) { Puppet::Type.type(:yumrepo).new(name: 'baseos') }
    let(:yumrepo_metadata_key_resource) { new_resource }

    it 'autorequires the yum repo' do
      catalog.add_resource(repo)
      catalog.add_resource(yumrepo_metadata_key_resource)

      relationships = yumrepo_metadata_key_resource.autorequire

      expect(relationships.map(&:source)).to include(repo)
      expect(relationships.map(&:target)).to include(yumrepo_metadata_key_resource)
    end
  end
end
