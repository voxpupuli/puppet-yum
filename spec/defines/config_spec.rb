# frozen_string_literal: true

require 'spec_helper'

describe 'yum::config' do
  context 'with no parameters' do
    let(:title) { 'assumeyes' }

    it { is_expected.to compile.and_raise_error(%r{expects a value for parameter 'ensure'}) }
  end

  %w[dnf yum].each do |pkgmgr|
    context "when package_provider fact is #{pkgmgr}" do
      let(:facts) { { package_provider: pkgmgr } }

      context 'when ensure is a Boolean' do
        let(:title) { 'assumeyes' }
        let(:params) { { ensure: true } }

        it { is_expected.to compile.with_all_deps }

        it 'contains an Augeas resource with the correct changes' do
          case pkgmgr
          when 'yum'
            is_expected.to contain_augeas("yum.conf_#{title}").with(
              incl: '/etc/yum.conf',
              context: '/files/etc/yum.conf/main/',
              changes: "set assumeyes '1'"
            )
          else
            is_expected.to contain_augeas("dnf.conf_#{title}").with(
              incl: '/etc/dnf/dnf.conf',
              context: '/files/etc/dnf/dnf.conf/main/',
              changes: "set assumeyes '1'"
            )
          end
        end
      end

      context 'ensure is an Integer' do
        let(:title) { 'assumeyes' }
        let(:params) { { ensure: 0 } }

        it { is_expected.to compile.with_all_deps }

        it 'contains an Augeas resource with the correct changes' do
          case pkgmgr
          when 'yum'
            is_expected.to contain_augeas("yum.conf_#{title}").with(
              changes: "set assumeyes '0'"
            )
          else
            is_expected.to contain_augeas("dnf.conf_#{title}").with(
              changes: "set assumeyes '0'"
            )
          end
        end
      end

      context 'ensure is a comma separated String' do
        let(:title) { 'assumeyes' }
        let(:params) { { ensure: '1, 2' } }

        it { is_expected.to compile.with_all_deps }

        it 'contains an Augeas resource with the correct changes' do
          case pkgmgr
          when 'yum'
            is_expected.to contain_augeas("yum.conf_#{title}").with(
              changes: "set assumeyes '1, 2'"
            )
          else
            is_expected.to contain_augeas("dnf.conf_#{title}").with(
              changes: "set assumeyes '1, 2'"
            )
          end
        end
      end

      context 'when ensure is a Sensitive[String]' do
        let(:title) { 'assumeyes' }
        let(:params) { { ensure: sensitive('secret') } }

        it { is_expected.to compile.with_all_deps }

        it 'contains an Augeas resource with the correct changes' do
          case pkgmgr
          when 'yum'
            is_expected.to contain_augeas("yum.conf_#{title}").with(
              changes: "set assumeyes 'secret'",
              show_diff: false
            )
          else
            is_expected.to contain_augeas("dnf.conf_#{title}").with(
              changes: "set assumeyes 'secret'",
              show_diff: false
            )
          end
        end
      end
    end
  end
end
