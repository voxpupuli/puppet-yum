# frozen_string_literal: true

require 'spec_helper'

describe 'yum::copr' do
  context 'with package_provider set to yum' do
    let(:facts) { { package_provider: 'yum' } }
    let(:prereq_plugin) { 'yum-plugin-copr' }
    let(:title) { 'copart/restic' }
    let(:copr_repo_name_part) { title.gsub('/', '-') }

    context 'package provider plugin installed' do
      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_package(prereq_plugin.to_s)
      }
    end

    context 'with ensure = enabled' do
      let(:params) { { ensure: 'enabled' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("yum -y copr enable #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'onlyif'  => "test ! -e /etc/yum.repos.d/_copr_#{copr_repo_name_part}.repo",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end

    context 'with ensure = disabled' do
      let(:params) { { ensure: 'disabled' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("yum -y copr disable #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'onlyif'  => "test -e /etc/yum.repos.d/_copr_#{copr_repo_name_part}.repo",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end

    context 'with ensure = removed' do
      let(:params) { { ensure: 'removed' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("yum -y copr disable #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'onlyif'  => "test -e /etc/yum.repos.d/_copr_#{copr_repo_name_part}.repo",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end
  end

  context 'with package_provider set to dnf' do
    let(:facts) { { package_provider: 'dnf' } }
    let(:prereq_plugin) { 'dnf-plugins-core' }
    let(:title) { 'copart/restic' }

    context 'package provider plugin installed' do
      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_package(prereq_plugin.to_s)
      }
    end

    context 'with ensure = enabled' do
      let(:params) { { ensure: 'enabled' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("dnf -y copr enable #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'unless'  => "dnf copr list | egrep -q '#{title}$'",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end

    context 'with ensure = disabled' do
      let(:params) { { ensure: 'disabled' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("dnf -y copr disable #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'unless'  => "dnf copr list | egrep -q '#{title} \\(disabled\\)$'",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end

    context 'with ensure = removed' do
      let(:params) { { ensure: 'removed' } }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec("dnf -y copr remove #{title}").with(
          'path'    => '/bin:/usr/bin:/sbin/:/usr/sbin',
          'onlyif'  => "dnf copr list | egrep -q '#{title}'",
          'require' => "Package[#{prereq_plugin}]"
        )
      }
    end
  end
end
