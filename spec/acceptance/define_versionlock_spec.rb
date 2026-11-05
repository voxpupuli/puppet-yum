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
    shell('dnf repolist', acceptable_exit_codes: [0])
    pp = <<-EOS
    class{yum::plugin::versionlock:
      clean => true,
    }
    # Not installed, but in an enabled repo on every supported OS; the version does not exist.
    yum::versionlock{'zsh':
      ensure  => present,
      version => '0.0.1',
      release => '1',
    }
    EOS
    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)

    # dnf list ignores versionlock, so check that install is filtered.
    shell('dnf install -y zsh 2>&1 | grep "All matches were filtered"', acceptable_exit_codes: [0])
  end
end
