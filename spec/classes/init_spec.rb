# frozen_string_literal: true

require 'spec_helper'
require 'deep_merge'

shared_examples 'a Yum class' do |value|
  value ||= 3

  it { is_expected.to contain_yum__config('installonly_limit').with_ensure(value.to_s) }

  it 'contains Exec[package-cleanup_oldkernels' do
    is_expected.to contain_exec('package-cleanup_oldkernels').with(
      command: %r{/usr/bin/dnf -y remove \$\(/usr/bin/dnf repoquery --installonly --latest-limit=-\$\{value\} | /usr/bin/grep -v \S+\)},
      refreshonly: true
    ).that_subscribes_to('Yum::Config[installonly_limit]')
  end
end

shared_examples 'a catalog containing repos' do |repos|
  repos.each do |repo|
    it { is_expected.to contain_yumrepo(repo) }
  end
end

shared_examples 'a catalog not containing repos' do |repos|
  repos.each do |repo|
    it { is_expected.not_to contain_yumrepo(repo) }
  end
end

describe 'yum' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('yum') }

      context 'without any parameters' do
        let(:params) { {} }

        it_behaves_like 'a Yum class'
        it { is_expected.to have_yumrepo_resource_count(0) }
        it { is_expected.to have_yum__group_resource_count(0) }
      end

      context 'with package_provider yum' do
        let(:facts) do
          facts.merge({ package_provider: 'yum' })
        end

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_exec('package-cleanup_oldkernels').with(
            command: '/usr/bin/package-cleanup --oldkernels --count=3 -y'
          )
        }
      end

      context 'when `manage_os_default_repos` is enabled' do
        let(:params) { { 'manage_os_default_repos' => true } }

        case facts[:os]['name']
        when 'Rocky'
          it_behaves_like 'a catalog containing repos', %w[
            appstream
            appstream-source
            baseos
            baseos-source
            devel
            extras
            ha
            ha-source
            nfv
            plus
            powertools
            powertools-source
            resilient-storage
            resilient-storage-source
            rt
          ]
          case facts[:os]['release']['major']
          when '8'
            it { is_expected.to have_yumrepo_resource_count(15) }
          else
            it { is_expected.to have_yumrepo_resource_count(0) } # rubocop:disable RSpec/RepeatedExample
          end
        when 'CentOS'
          case facts[:os]['release']['major']
          when '9'
            it_behaves_like 'a catalog containing repos', %w[
              appstream
              baseos
              crb
              extras-common
              appstream-source
              appstream-debug
              baseos-source
              baseos-debug
              crb-source
              crb-debug
              highavailability
              highavailability-source
              highavailability-debug
              nfv
              nfv-source
              nfv-debug
              rt
              rt-source
              rt-debug
              resilientstorage
              resilientstorage-source
              resilientstorage-debug
              extras-common
              extras-common-source
            ]
            it_behaves_like 'a catalog not containing repos', %w[
              AppStream
              BaseOS
              cr
              Devel
              HA
              PowerTools
              BaseOS-source
              Appstream-source
              c8-media-BaseOS
              c8-media-AppStream
            ]
          when '8'
            it_behaves_like 'a catalog containing repos', %w[
              AppStream
              BaseOS
              cr
              Devel
              HA
              PowerTools
              BaseOS-source
              Appstream-source
              c8-media-BaseOS
              c8-media-AppStream
              extras
              centosplus
              fasttrack
              extras-source
              base-debuginfo
            ]
            it_behaves_like 'a catalog not containing repos', %w[
              base
              updates
              contrib
              base-source
              updates-source
              centos-media
            ]
          when '7'
            it_behaves_like 'a catalog containing repos', %w[
              base
              updates
              cr
              base-source
              updates-source
              centos-media
              extras
              centosplus
              fasttrack
              extras-source
              base-debuginfo
            ]
            it_behaves_like 'a catalog not containing repos', %w[
              contrib
              AppStream
              BaseOS
              Devel
              HA
              PowerTools
              BaseOS-source
              Appstream-source
              c8-media-BaseOS
              c8-media-AppStream
            ]
          else
            it { is_expected.to have_yumrepo_resource_count(4) }
          end
        when 'Amazon'
          it { is_expected.to have_yumrepo_resource_count(16) } # rubocop:disable RSpec/RepeatedExample

          it_behaves_like 'a catalog containing repos', %w[
            amzn-main
            amzn-main-debuginfo
            amzn-main-source
            amzn-nosrc
            amzn-preview
            amzn-preview-debuginfo
            amzn-preview-source
            amzn-updates
            amzn-updates-debuginfo
            amzn-updates-source
            epel
            epel-debuginfo
            epel-source
            epel-testing
            epel-testing-debuginfo
            epel-testing-source
          ]
        when 'RedHat'
          it { is_expected.to have_yumrepo_resource_count(18) }

          it_behaves_like 'a catalog containing repos', %w[
            rhui-REGION-rhel-server-releases
            rhui-REGION-rhel-server-releases-debug
            rhui-REGION-rhel-server-releases-source
            rhui-REGION-rhel-server-rhscl
            rhui-REGION-rhel-server-debug-rhscl
            rhui-REGION-rhel-server-source-rhscl
            rhui-REGION-rhel-server-extras
            rhui-REGION-rhel-server-debug-extras
            rhui-REGION-rhel-server-source-extras
            rhui-REGION-rhel-server-optional
            rhui-REGION-rhel-server-debug-optional
            rhui-REGION-rhel-server-source-optional
            rhui-REGION-rhel-server-rh-common
            rhui-REGION-rhel-server-debug-rh-common
            rhui-REGION-rhel-server-source-rh-common
            rhui-REGION-rhel-server-supplementary
            rhui-REGION-rhel-server-debug-supplementary
            rhui-REGION-rhel-server-source-supplementary
          ]
        when 'VirtuozzoLinux'
          case facts[:os]['release']['major']
          when '6'
            it { is_expected.to have_yumrepo_resource_count(12) }

            it_behaves_like 'a catalog containing repos', %w[
              virtuozzolinux-base
              virtuozzolinux-updates
              virtuozzolinux-base-debuginfo
              virtuozzolinux-updates-debuginfo
              virtuozzolinux-factory
              virtuozzolinux-factory-debuginfo
              virtuozzo-os
              virtuozzo-updates
              virtuozzo-os-debuginfo
              virtuozzo-updates-debuginfo
              virtuozzo-readykernel
              obsoleted_tmpls
            ]
          when '7'
            it { is_expected.to have_yumrepo_resource_count(16) } # rubocop:disable RSpec/RepeatedExample

            it_behaves_like 'a catalog containing repos', %w[
              virtuozzolinux-base
              virtuozzolinux-updates
              virtuozzolinux-base-debuginfo
              virtuozzolinux-updates-debuginfo
              virtuozzolinux-factory
              virtuozzolinux-factory-debuginfo
              virtuozzo-os
              virtuozzo-updates
              virtuozzo-os-debuginfo
              virtuozzo-updates-debuginfo
              virtuozzo-readykernel
              obsoleted_tmpls
              factory
              factory-debuginfo
              virtuozzolinux-vz-factory
              virtuozzolinux-vz-factory-debuginfo
            ]
          end
        when 'AlmaLinux'
          case facts[:os]['release']['major']
          when '8'
            it { is_expected.to have_yumrepo_resource_count(21) }

            it_behaves_like 'a catalog containing repos', %w[
              baseos
              appstream
              powertools
              extras
              ha
              plus
              resilientstorage
              baseos-source
              appstream-source
              powertools-source
              extras-source
              ha-source
              plus-source
              resilientstorage-source
              baseos-debuginfo
              appstream-debuginfo
              powertools-debuginfo
              extras-debuginfo
              ha-debuginfo
              plus-debuginfo
              resilientstorage-debuginfo
            ]
          end
        when 'Fedora'
          it { is_expected.to have_yumrepo_resource_count(11) }

          it_behaves_like 'a catalog containing repos', %w[
            fedora
            fedora-debuginfo
            fedora-source
            fedora-cisco-openh264
            fedora-cisco-openh264-debuginfo
            updates
            updates-debuginfo
            updates-source
            updates-testing
            updates-testing-debuginfo
            updates-testing-source
          ]
        else
          it { is_expected.to have_yumrepo_resource_count(0) } # rubocop:disable RSpec/RepeatedExample
        end

        context 'and the CentOS base repo is negated' do
          case facts[:os]['release']['major']
          when '8'
            let(:params) { super().merge(repo_exclusions: ['BaseOS']) }
          else
            let(:params) { super().merge(repo_exclusions: ['base']) }
          end

          it { is_expected.to compile.with_all_deps }

          case facts[:os]['name']
          when 'CentOS'
            it { is_expected.not_to contain_yumrepo('base') }
            it { is_expected.not_to contain_yumrepo('BaseOS') }

            case facts[:os]['release']['major']
            when '9'
              it_behaves_like 'a catalog containing repos', %w[
                appstream
                baseos
                crb
                extras-common
                appstream-source
                appstream-debug
                baseos-source
                baseos-debug
                crb-source
                crb-debug
                highavailability
                highavailability-source
                highavailability-debug
                nfv
                nfv-source
                nfv-debug
                rt
                rt-source
                rt-debug
                resilientstorage
                resilientstorage-source
                resilientstorage-debug
                extras-common
                extras-common-source
              ]
            when '8'
              it_behaves_like 'a catalog containing repos', %w[
                AppStream
                cr
                Devel
                fasttrack
                HA
                PowerTools
                BaseOS-source
                Appstream-source
                c8-media-BaseOS
                c8-media-AppStream
                extras
                centosplus
                extras-source
                base-debuginfo
              ]
            when '7'
              it_behaves_like 'a catalog containing repos', %w[
                cr
                updates
                extras
                base-source
                updates-source
                extras-source
                base-debuginfo
                centosplus
                centos-media
                extras
                centosplus
                extras-source
                base-debuginfo
              ]
            when '6'
              it_behaves_like 'a catalog containing repos', %w[
                contrib
                updates
                extras
                base-source
                updates-source
                extras-source
                base-debuginfo
                centosplus
                centos-media
              ]
            end
          when 'Amazon'
            it { is_expected.to have_yumrepo_resource_count(16) } # rubocop:disable RSpec/RepeatedExample

            it_behaves_like 'a catalog containing repos', %w[
              amzn-main
              amzn-main-debuginfo
              amzn-main-source
              amzn-nosrc
              amzn-preview
              amzn-preview-debuginfo
              amzn-preview-source
              amzn-updates
              amzn-updates-debuginfo
              amzn-updates-source
              epel
              epel-debuginfo
              epel-source
              epel-testing
              epel-testing-debuginfo
              epel-testing-source
            ]
          when 'RedHat'
            it { is_expected.to have_yumrepo_resource_count(18) }

            it_behaves_like 'a catalog containing repos', %w[
              rhui-REGION-rhel-server-releases
              rhui-REGION-rhel-server-releases-debug
              rhui-REGION-rhel-server-releases-source
              rhui-REGION-rhel-server-rhscl
              rhui-REGION-rhel-server-debug-rhscl
              rhui-REGION-rhel-server-source-rhscl
              rhui-REGION-rhel-server-extras
              rhui-REGION-rhel-server-debug-extras
              rhui-REGION-rhel-server-source-extras
              rhui-REGION-rhel-server-optional
              rhui-REGION-rhel-server-debug-optional
              rhui-REGION-rhel-server-source-optional
              rhui-REGION-rhel-server-rh-common
              rhui-REGION-rhel-server-debug-rh-common
              rhui-REGION-rhel-server-source-rh-common
              rhui-REGION-rhel-server-supplementary
              rhui-REGION-rhel-server-debug-supplementary
              rhui-REGION-rhel-server-source-supplementary
            ]
          when 'VirtuozzoLinux'
            case facts[:os]['release']['major']
            when '6'
              it { is_expected.to have_yumrepo_resource_count(12) }

              it_behaves_like 'a catalog containing repos', %w[
                virtuozzolinux-base
                virtuozzolinux-updates
                virtuozzolinux-base-debuginfo
                virtuozzolinux-updates-debuginfo
                virtuozzolinux-factory
                virtuozzolinux-factory-debuginfo
                virtuozzo-os
                virtuozzo-updates
                virtuozzo-os-debuginfo
                virtuozzo-updates-debuginfo
                virtuozzo-readykernel
                obsoleted_tmpls
              ]
            when '7'
              it { is_expected.to have_yumrepo_resource_count(16) } # rubocop:disable RSpec/RepeatedExample

              it_behaves_like 'a catalog containing repos', %w[
                virtuozzolinux-base
                virtuozzolinux-updates
                virtuozzolinux-base-debuginfo
                virtuozzolinux-updates-debuginfo
                virtuozzolinux-factory
                virtuozzolinux-factory-debuginfo
                virtuozzo-os
                virtuozzo-updates
                virtuozzo-os-debuginfo
                virtuozzo-updates-debuginfo
                virtuozzo-readykernel
                obsoleted_tmpls
                factory
                factory-debuginfo
                virtuozzolinux-vz-factory
                virtuozzolinux-vz-factory-debuginfo
              ]
            end
          when 'AlmaLinux'
            case facts[:os]['release']['major']
            when '8'
              it { is_expected.to have_yumrepo_resource_count(21) }

              it_behaves_like 'a catalog containing repos', %w[
                baseos
                appstream
                powertools
                extras
                ha
                plus
                resilientstorage
                baseos-source
                appstream-source
                powertools-source
                extras-source
                ha-source
                plus-source
                resilientstorage-source
                baseos-debuginfo
                appstream-debuginfo
                powertools-debuginfo
                extras-debuginfo
                ha-debuginfo
                plus-debuginfo
                resilientstorage-debuginfo
              ]
            when '9'
              it { is_expected.to have_yumrepo_resource_count(33) }

              it_behaves_like 'a catalog containing repos', %w[
                appstream
                appstream-debuginfo
                appstream-source
                plus
                plus-debuginfo
                plus-source
                saphana
                saphana-debuginfo
                saphana-source
                crb
                crb-debuginfo
                crb-source
                baseos
                baseos-debuginfo
                baseos-source
                highavailability
                highavailability-debuginfo
                highavailability-source
                extras
                extras-debuginfo
                extras-source
                nfv
                nfv-debuginfo
                nfv-source
                resilientstorage
                resilientstorage-debuginfo
                resilientstorage-source
                rt
                rt-debuginfo
                rt-source
                sap
                sap-debuginfo
                sap-source
              ]
            end
          when 'Rocky'
            case facts[:os]['release']['major']
            when '8'
              it { is_expected.to have_yumrepo_resource_count(15) }

              it_behaves_like 'a catalog containing repos', %w[
                appstream
                appstream-source
                baseos
                baseos-source
                devel
                extras
                ha
                ha-source
                nfv
                plus
                powertools
                powertools-source
                resilient-storage
                resilient-storage-source
                rt
              ]
            end
          when 'Fedora'
            it { is_expected.to have_yumrepo_resource_count(11) }

            it_behaves_like 'a catalog containing repos', %w[
              fedora
              fedora-debuginfo
              fedora-source
              fedora-cisco-openh264
              fedora-cisco-openh264-debuginfo
              updates
              updates-debuginfo
              updates-source
              updates-testing
              updates-testing-debuginfo
              updates-testing-source
            ]
          else
            it { is_expected.to have_yumrepo_resource_count(0) }
          end
        end
      end

      context 'when `managed_repos` is set' do
        # TODO: This should be generated with something like `lookup('yum::repos').keys`,
        # but the setup for `Puppet::Pops::Lookup` is to complicated to be worth it as of
        # this writing (2017-04-11).  For now, we just pull from `repos.yaml`.

        repos_yaml_data = YAML.safe_load(File.read('./spec/fixtures/modules/yum/data/repos/repos.yaml'))

        case facts[:os]['family']
        when 'RedHat'
          case facts[:os]['release']['major']
          when '8'
            rh8_repos_yaml_data = YAML.safe_load(File.read('./spec/fixtures/modules/yum/data/repos/RedHat/8.yaml'))
            repos_yaml_data = repos_yaml_data.deep_merge(rh8_repos_yaml_data)
          end
        end

        supported_repos = repos_yaml_data['yum::repos'].keys

        supported_repos.each do |supported_repo|
          context "to ['#{supported_repo}']" do
            let(:params) { { managed_repos: [supported_repo] } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to have_yumrepo_resource_count(1) }
            it { is_expected.to contain_yumrepo(supported_repo) }
          end
        end

        context 'to an array of all supported repos' do
          let(:params) { { managed_repos: supported_repos } }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to have_yumrepo_resource_count(supported_repos.count) }

          it_behaves_like 'a catalog containing repos', supported_repos
        end
      end

      context 'when `config_options[installonly_limit]` is modified' do
        context 'with an Integer' do
          let(:params) { { config_options: { 'installonly_limit' => 10 } } }

          it_behaves_like 'a Yum class', 10
        end

        context 'with an invalid data type' do
          let(:params) { { config_options: { 'installonly_limit' => false } } }

          it 'raises a useful error' do
            is_expected.to compile.and_raise_error(
              %r{The value or ensure for `\$yum::config_options\[installonly_limit\]` must be an Integer, but it is not\.}
            )
          end
        end
      end

      context 'when a config option other than `installonly_limit` is set' do
        context 'to a String' do
          let(:params) { { config_options: { 'cachedir' => '/var/cache/yum' } } }

          it { is_expected.to contain_yum__config('cachedir').with_ensure('/var/cache/yum') }

          it_behaves_like 'a Yum class'
        end

        context 'to an Integer' do
          let(:params) { { config_options: { 'debuglevel' => 5 } } }

          it { is_expected.to contain_yum__config('debuglevel').with_ensure('5') }

          it_behaves_like 'a Yum class'
        end

        context 'to a Boolean' do
          let(:params) { { config_options: { 'gpgcheck' => true } } }

          it { is_expected.to contain_yum__config('gpgcheck').with_ensure('1') }

          it_behaves_like 'a Yum class'
        end

        context 'to a Sensitive value' do
          let(:params) { { config_options: { 'proxy_password' => sensitive('secret') } } }

          it { is_expected.to contain_yum__config('proxy_password').with_ensure('Sensitive("secret")') }

          it_behaves_like 'a Yum class'
        end

        context 'using the nested attributes syntax' do
          context 'to a String' do
            let(:params) { { config_options: { 'my_cachedir' => { 'ensure' => '/var/cache/yum', 'key' => 'cachedir' } } } }

            it { is_expected.to contain_yum__config('my_cachedir').with_ensure('/var/cache/yum').with_key('cachedir') }

            it_behaves_like 'a Yum class'
          end

          context 'to an Integer' do
            let(:params) { { config_options: { 'my_debuglevel' => { 'ensure' => 5, 'key' => 'debuglevel' } } } }

            it { is_expected.to contain_yum__config('my_debuglevel').with_ensure('5').with_key('debuglevel') }

            it_behaves_like 'a Yum class'
          end

          context 'to a Boolean' do
            let(:params) { { config_options: { 'my_gpgcheck' => { 'ensure' => true, 'key' => 'gpgcheck' } } } }

            it { is_expected.to contain_yum__config('my_gpgcheck').with_ensure('1').with_key('gpgcheck') }

            it_behaves_like 'a Yum class'
          end
        end
      end

      context 'when clean_old_kernels => false' do
        let(:params) { { clean_old_kernels: false } }

        it { is_expected.to contain_exec('package-cleanup_oldkernels').without_subscribe }
      end

      context 'when epel is enabled' do
        let(:params) { { managed_repos: ['epel'] } }

        it { is_expected.to contain_yumrepo('epel') }

        case facts[:os]['release']['major']
        when '9'
          it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9') }
        when '8'
          it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8') }
        when '7'
          it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7') }
        when '6'
          it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6') }
        end
      end

      context 'when utils_package_name is not set' do
        it { is_expected.to compile.with_all_deps }

        case facts[:os]['name']
        when 'Fedora'
          it { is_expected.to contain_package('dnf-utils') }
        else
          it { is_expected.to contain_package('yum-utils') }
        end
      end

      context 'when utils_package_name is set' do
        let(:params) { { utils_package_name: 'dnf-utils' } }

        it { is_expected.not_to contain_package('yum-utils') }
        it { is_expected.to contain_package('dnf-utils') }
      end

      context 'when custom repos is set' do
        let(:params) do
          {
            managed_repos: ['example'],
            repos: {
              example: {
                baseurl: 'https://example.com',
                gpgkey: 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-example'
              }
            },
            gpgkeys: {
              '/etc/pki/rpm-gpg/RPM-GPG-KEY-example' => {
                'source' => 'http://example.com/gpg'
              }
            }
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_yumrepo_resource_count(1) }
        it { is_expected.to contain_yumrepo('example') }
        it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-example') }
      end

      context 'when custom repos with multiple gpgkeys is set' do
        let(:params) do
          {
            managed_repos: ['example'],
            repos: {
              example: {
                baseurl: 'https://example.com',
                gpgkey: 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-example file:///etc/pki/rpm-gpg/RPM-GPG-KEY-example2',
              }
            },
            gpgkeys: {
              '/etc/pki/rpm-gpg/RPM-GPG-KEY-example' => {
                'source' => 'http://example.com/gpg'
              },
              '/etc/pki/rpm-gpg/RPM-GPG-KEY-example2' => {
                'source' => 'http://example.com/gpg2'
              }
            }
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to have_yumrepo_resource_count(1) }
        it { is_expected.to contain_yumrepo('example') }
        it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-example') }
        it { is_expected.to contain_yum__gpgkey('/etc/pki/rpm-gpg/RPM-GPG-KEY-example2') }
      end

      context 'when groups parameter is set' do
        let(:params) do
          {
            groups: {
              'Dev Tools': {
                ensure: 'installed',
              },
              'Puppet Tools': {
                ensure: 'absent',
              },
            },
          }
        end

        it { is_expected.to contain_yum__group('Puppet Tools').with_ensure('absent') }
        it { is_expected.to contain_yum__group('Dev Tools').with_ensure('installed') }
      end
    end
  end

  context 'on an unsupported operating system' do
    let(:facts) { { os: { family: 'Solaris', name: 'Nexenta' } } }

    it { is_expected.to raise_error(Puppet::Error, %r{Nexenta not supported}) }
  end
end
