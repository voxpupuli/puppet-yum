# frozen_string_literal: true

require 'spec_helper'

describe 'yum::plugin::post_transaction_actions' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      %w[yum dnf].each do |provider|
        context "with package_provider #{provider}" do
          let(:facts) do
            os_facts.merge(package_provider: provider)
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_concat('puppet_actions') }
          it { is_expected.to contain_concat__fragment('action_header') }

          case provider
          when 'yum'
            it { is_expected.to contain_package('yum-plugin-post-transaction-actions').with_ensure('present') }
            it { is_expected.not_to contain_package('python3-dnf-plugin-post-transaction-actions') }
            it { is_expected.to contain_concat('puppet_actions').with_path('/etc/yum/post-actions/puppet_maintained.action') }
          else
            it { is_expected.to contain_package('python3-dnf-plugin-post-transaction-actions').with_ensure('present') }
            it { is_expected.not_to contain_package('yum-plugin-post-transaction-actions') }
            it { is_expected.to contain_concat('puppet_actions').with_path('/etc/dnf/plugins/post-transaction-actions.d/puppet_maintained.action') }
          end
          context 'with plugin disable' do
            let(:params) do
              { ensure: 'absent' }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.not_to contain_concat('puppet_actions') }
            it { is_expected.not_to contain_concat__fragment('action_header') }

            case provider
            when 'yum'
              it { is_expected.to contain_package('yum-plugin-post-transaction-actions').with_ensure('absent') }
              it { is_expected.not_to contain_package('python3-dnf-plugin-post-transaction-actions') }
            else
              it { is_expected.to contain_package('python3-dnf-plugin-post-transaction-actions').with_ensure('absent') }
              it { is_expected.not_to contain_package('yum-plugin-post-transaction-actions') }
            end
          end
        end
      end
    end
  end
end
