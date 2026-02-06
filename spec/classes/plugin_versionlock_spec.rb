# frozen_string_literal: true

require 'spec_helper'

describe 'yum::plugin::versionlock' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_package('python3-dnf-plugin-versionlock').with_ensure('present') }
      it { is_expected.not_to contain_package('yum-plugin-versionlock') }
      it { is_expected.to contain_concat__fragment('versionlock_header').with_target('/etc/dnf/plugins/versionlock.list') }

      context 'with plugin disable' do
        let(:params) do
          { ensure: 'absent' }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_concat__fragment('versionlock_header') }

        it { is_expected.to contain_package('python3-dnf-plugin-versionlock').with_ensure('absent') }
        it { is_expected.not_to contain_package('yum-plugin-versionlock') }
      end
    end
  end
end
