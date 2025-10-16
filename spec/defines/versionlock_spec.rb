# frozen_string_literal: true

require 'spec_helper'

describe 'yum::versionlock' do
  context 'with package_provider set to yum' do
    let(:facts) do
      { os: { release: { major: 7 } },
        package_provider: 'yum' }
    end

    context 'with a simple, well-formed title 0:bash-4.1.2-9.el6_2.x86_64' do
      let(:title) { '0:bash-4.1.2-9.el6_2.x86_64' }

      context 'and no parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('versionlock_header').with_content("# File managed by puppet\n") }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("#{title}\n")
        end

        it { is_expected.to contain_concat('/etc/yum/pluginconf.d/versionlock.list').without_notify }
      end

      context 'clean set to true on module' do
        let :pre_condition do
          'class { "yum::plugin::versionlock": clean => true, }'
        end

        it { is_expected.to contain_concat('/etc/yum/pluginconf.d/versionlock.list').with_notify('Exec[yum_clean_all]') }
        it { is_expected.to contain_exec('yum_clean_all').with_command('/usr/bin/yum clean all') }
      end

      context 'and ensure set to present' do
        let(:params) { { ensure: 'present' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('versionlock_header').with_content("# File managed by puppet\n") }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("#{title}\n")
        end
      end

      context 'and ensure set to absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat__fragment('versionlock_header').with_content("# File managed by puppet\n") }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.not_to contain_concat__fragment("yum-versionlock-#{title}")
        end
      end

      context 'with version set namevar must be just a package name' do
        let(:params) { { version: '4.3' } }

        it { is_expected.to compile.and_raise_error(%r{Package name must be formatted as Yum::RpmName, not 'String'}) }
      end
    end

    context 'with a trailing wildcard title' do
      let(:title) { '0:bash-4.1.2-9.el6_2.*' }

      it { is_expected.to compile.with_all_deps }

      it 'contains a well-formed Concat::Fragment' do
        is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("#{title}\n")
      end
    end

    context 'with a complex wildcard title' do
      let(:title) { '0:bash-4.*-*.el6' }

      it 'contains a well-formed Concat::Fragment' do
        is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("#{title}\n")
      end
    end

    context 'with a release containing dots' do
      let(:title) { '1:java-1.7.0-openjdk-1.7.0.121-2.6.8.0.el7_3.x86_64' }

      it 'contains a well-formed Concat::Fragment' do
        is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("#{title}\n")
      end
    end

    context 'with an invalid title' do
      let(:title) { 'bash-4.1.2' }

      it { is_expected.to compile.and_raise_error(%r(%\{EPOCH\}:%\{NAME\}-%\{VERSION\}-%\{RELEASE\}\.%\{ARCH\})) }
    end

    context 'with an invalid wildcard pattern' do
      let(:title) { '0:bash-4.1.2*' }

      it { is_expected.to compile.and_raise_error(%r(%\{EPOCH\}:%\{NAME\}-%\{VERSION\}-%\{RELEASE\}\.%\{ARCH\})) }
    end
  end

  context 'with a simple, well-formed package name title bash and a version' do
    let(:facts) do
      { os: { release: { major: 7 } },
        package_provider: 'yum' }
    end

    let(:title) { 'bash' }
    let(:params) { { version: '4.3' } }

    context 'with version set' do
      it { is_expected.to compile.with_all_deps }

      it 'contains a well-formed Concat::Fragment' do
        is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("0:bash-4.3-*.*\n")
      end
    end

    context 'with version, release, epoch and arch set as strings' do
      let(:params) do
        {
          version: '4.3',
          release: '3.2',
          arch: 'arm',
          epoch: '42'
        }
      end

      context 'it works' do
        it { is_expected.to compile.with_all_deps }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("42:bash-4.3-3.2.arm\n")
        end
      end
    end

    context 'with version, release, epoch and arch set as numbers' do
      let(:params) do
        {
          version: 4.3,
          release: 3.2,
          arch: 'arm',
          epoch: 42
        }
      end

      context 'it works' do
        it { is_expected.to compile.with_all_deps }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("42:bash-4.3-3.2.arm\n")
        end
      end
    end
  end

  context 'with package_provider set to dnf' do
    let(:facts) do
      { os: { release: { major: 8 } },
        package_provider: 'dnf' }
    end

    context 'with a simple, well-formed title, no version set' do
      let(:title) { 'bash' }

      it { is_expected.to compile.and_raise_error(%r{Version must be formatted as Yum::RpmVersion}) }

      context 'and a version set to 4.3' do
        let(:params) { { version: '4.3' } }

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-0:4.3-*.*\n")
        end

        context 'and an arch set to x86_64' do
          let(:params)  { super().merge(arch: 'x86_64') }

          it 'contains a well-formed Concat::Fragment' do
            is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-0:4.3-*.x86_64\n")
          end
        end

        context 'and an release set to 22.x' do
          let(:params) { super().merge(release: '22.5') }

          it 'contains a well-formed Concat::Fragment' do
            is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-0:4.3-22.5.*\n")
          end
        end

        context 'and an epoch set to 5' do
          let(:params) { super().merge(epoch: 5) }

          it 'contains a well-formed Concat::Fragment' do
            is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-5:4.3-*.*\n")
          end
        end
      end

      context 'with release, version, epoch, arch all set' do
        let(:params) do
          {
            version: '22.5',
            release: 'alpha12',
            epoch: 8,
            arch: 'i386'
          }
        end

        it 'contains a well-formed Concat::Fragment' do
          is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-8:22.5-alpha12.i386\n")
        end
      end
    end
  end

  context 'with package_provider unset' do
    let(:facts) do
      { os: { release: { major: 7 } } }
    end
    let(:title) { 'bash' }
    let(:params) { { version: '4.3' } }

    it { is_expected.to compile.with_all_deps }

    it 'contains a well-formed Concat::Fragment' do
      is_expected.to contain_concat__fragment('yum-versionlock-bash').with_content("bash-0:4.3-*.*\n")
    end
  end
end
