# frozen_string_literal: true

require 'spec_helper'

describe 'yum::group' do
  context 'with no parameters' do
    let(:title) { 'Core' }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("yum-groupinstall-#{title}").with_command("yum -y group install 'Core'") }
  end

  context 'when ensure is set to `absent`' do
    let(:title) { 'Core' }
    let(:params) { { ensure: 'absent' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("yum-groupremove-#{title}").with_command("yum -y group remove 'Core'") }
  end

  context 'with a timeout specified' do
    let(:title) { 'Core' }
    let(:params) { { timeout: 30 } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("yum-groupinstall-#{title}").with_timeout(30) }
  end

  context 'with an install option specified' do
    let(:title) { 'Core' }
    let(:params) { { install_options: ['--enablerepo=epel'] } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("yum-groupinstall-#{title}").with_command("yum -y group install 'Core' --enablerepo=epel") }
  end

  context 'when ensure is set to `latest`' do
    let(:title) { 'Core' }
    let(:params) { { ensure: 'latest' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec("yum-groupinstall-#{title}").with_command("yum -y group install 'Core'") }
    it { is_expected.to contain_exec("yum-groupinstall-#{title}-latest").with_command("yum -y group install 'Core'") }
  end
end
