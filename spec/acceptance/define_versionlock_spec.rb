# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::versionlock define' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::versionlock{ 'bash':
        ensure  => present,
        version => '4.1.2',
        release => '9.el6_2',
      }
      yum::versionlock{ 'tcsh':
        ensure  => present,
        version => '3.1.2',
        release => '9.el6_2',
        arch    => '*',
        epoch   => 0,
      }

      # Lock a package with new style on all OSes
      yum::versionlock{ 'netscape':
        ensure  => present,
        version => '8.1.2',
        release => '9.el6_2',
        arch    => '*',
        epoch   => 2,
      }

      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    describe file('/etc/dnf/plugins/versionlock.list') do
      it { is_expected.to be_file }

      it { is_expected.to contain 'bash-0:4.1.2-9.el6_2.*' }
      it { is_expected.to contain 'tcsh-0:3.1.2-9.el6_2.*' }
      it { is_expected.to contain 'netscape-2:8.1.2-9.el6_2.*' }
    end

    describe package('python3-dnf-plugin-versionlock') do
      it { is_expected.to be_installed }
    end
  end

  it 'must work if clean is specified' do
    shell('yum repolist', acceptable_exit_codes: [0])
    pp = <<-EOS
    class{yum::plugin::versionlock:
      clean => true,
    }
    # Pick an obscure package that hopefully will not be installed.
    yum::versionlock{'samba-devel':
      ensure  => present,
      version => '3.1.2',
      release => '9.el6_2',
    }
    EOS
    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)

    shell('dnf -q list --available samba-devel', acceptable_exit_codes: [1])
  end
end
