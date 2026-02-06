# frozen_string_literal: true

require 'spec_helper'

describe 'yum::versionlock' do
  # old deprecated yum EL7 style
  context 'with the old style yum strings 0:bash-4.1.2-9.el6_2.x86_64' do
    let(:title) { '0:bash-4.1.2-9.el6_2.x86_64' }

    it { is_expected.to compile.and_raise_error(%r{expects a match for Yum::RpmNameGlob}) }
  end

  context 'with a simple, well-formed package name' do
    let(:title) { 'bash' }

    it { is_expected.to compile.and_raise_error(%r{The version parameter must be set}) }

    context 'with ensure absent' do
      let(:params) { { ensure: 'absent' } }

      it 'does not contain a well-formed Concat::Fragment' do
        is_expected.not_to contain_concat__fragment('yum-versionlock-bash')
      end
    end

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
          is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("bash-42:4.3-3.2.arm\n")
        end
      end
    end
  end

  context 'with a globby package name' do
    let(:title) { 'tcsh*' }
    let(:params) do
      {
        version: 4.3,
      }
    end

    it 'contains a well-formed Concat::Fragment' do
      is_expected.to contain_concat__fragment("yum-versionlock-#{title}").with_content("tcsh*-0:4.3-*.*\n")
    end
  end
end
