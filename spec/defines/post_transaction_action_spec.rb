require 'spec_helper'

describe 'yum::post_transaction_action' do
  let(:title) { 'an entry' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      %w[yum dnf].each do |provider|
        context "with package_provider #{provider}" do
          let(:facts) do
            os_facts.merge(package_provider: provider)
          end

          context 'with simple package name and state any' do
            let(:params) do
              {
                key: 'openssh',
                state: 'any',
                command: 'foo bar',
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('yum::plugin::post_transaction_actions') }
            it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^# Action name: an entry$}) }
            it {
              is_expected.to contain_concat__fragment('post_trans_an entry').with(
                {
                  target: 'puppet_actions',
                  order: '10',
                  content: %r{^openssh:any:foo bar$},
                }
              )
            }
            context 'with post_transaction_actions disabled' do
              let(:pre_condition) { 'class{"yum::plugin::post_transaction_actions": ensure => "absent"}' }

              it { is_expected.to compile.with_all_deps }
              it { is_expected.to contain_class('yum::plugin::post_transaction_actions') }
              it { is_expected.not_to contain_concat__fragment('post_trans_an entry') }
            end
          end
          context 'with package name glob and state any' do
            let(:params) do
              {
                key: 'openssh-*',
                state: 'any',
                command: 'foo bar',
              }
            end

            it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^openssh-\*:any:foo bar$}) }
          end
          context 'with file name path and state any' do
            let(:params) do
              {
                key: '/etc/passwd',
                state: 'any',
                command: 'foo bar',
              }
            end

            it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^/etc/passwd:any:foo bar$}) }
          end
          context 'with file name glob and state any' do
            let(:params) do
              {
                key: '/etc/*',
                state: 'any',
                command: 'foo bar',
              }
            end

            it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^/etc/\*:any:foo bar$}) }
          end
          context 'with simple package name and state in (dnf only option)' do
            let(:params) do
              {
                key: 'openssh',
                state: 'in',
                command: 'foo bar',
              }
            end

            case provider
            when 'yum'
              it { is_expected.to raise_error(%r{The state parameter on}) }
            else
              it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^openssh:in:foo bar$}) }
            end
          end
          context 'with simple package name and state install (yum only option)' do
            let(:params) do
              {
                key: 'openssh',
                state: 'install',
                command: 'foo bar',
              }
            end

            case provider
            when 'yum'
              it { is_expected.to contain_concat__fragment('post_trans_an entry').with_content(%r{^openssh:install:foo bar$}) }
            else
              it { is_expected.to raise_error(%r{The state parameter on}) }
            end
          end
        end
      end
    end
  end
end
