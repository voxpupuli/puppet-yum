# frozen_string_literal: true

require 'spec_helper'

describe 'yum::plugin::versionlock' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      %w[yum dnf].each do |provider|
        context "with package_provider #{provider}" do
          let(:facts) do
            os_facts.merge(package_provider: provider)
          end

          it { is_expected.to compile.with_all_deps }

          case provider
          when 'yum'
            it { is_expected.to contain_package('yum-plugin-versionlock').with_ensure('present') }
            it { is_expected.not_to contain_package('python3-dnf-plugin-versionlock') }
            it { is_expected.to contain_concat__fragment('versionlock_header').with_target('/etc/yum/pluginconf.d/versionlock.list') }
          else
            it { is_expected.to contain_package('python3-dnf-plugin-versionlock').with_ensure('present') }
            it { is_expected.not_to contain_package('yum-plugin-versionlock') }
            it { is_expected.to contain_concat__fragment('versionlock_header').with_target('/etc/dnf/plugins/versionlock.list') }
          end
          context 'with plugin disable' do
            let(:params) do
              { ensure: 'absent' }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to contain_concat__fragment('versionlock_header') }

            case provider
            when 'yum'
              it { is_expected.to contain_package('yum-plugin-versionlock').with_ensure('absent') }
              it { is_expected.not_to contain_package('python3-dnf-plugin-versionlock') }
            else
              it { is_expected.to contain_package('python3-dnf-plugin-versionlock').with_ensure('absent') }
              it { is_expected.not_to contain_package('yum-plugin-versionlock') }
            end
          end

          context 'with locked package' do
            let(:params) do
              {
                'packages' => {
                  'bash' => {
                    'version' => '4.1.2',
                    'release' => '9.el8.2.*',
                    'epoch' => 0,
                    'arch' => 'x86_64',
                  }
                }
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_yum__versionlock('bash') }
          end
        end
      end
    end
  end
end
