# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::versionlock define' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      if versioncmp($facts['os']['release']['major'],'7') <= 0 {
        yum::versionlock{ '0:bash-4.1.2-9.el6_2.*':
          ensure => present,
        }
        yum::versionlock{ '0:tcsh-3.1.2-9.el6_2.*':
          ensure => present,
        }
      } else {
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

    if fact('os.release.major') == '7'
      describe file('/etc/yum/pluginconf.d/versionlock.list') do
        it { is_expected.to be_file }
        it { is_expected.to contain '0:bash-4.1.2-9.el6_2.*' }
        it { is_expected.to contain '0:tcsh-3.1.2-9.el6_2.*' }
        it { is_expected.to contain '2:netscape-8.1.2-9.el6_2.*' }
      end
    else
      describe file('/etc/dnf/plugins/versionlock.list') do
        it { is_expected.to be_file }

        it { is_expected.to contain 'bash-0:4.1.2-9.el6_2.*' }
        it { is_expected.to contain 'tcsh-0:3.1.2-9.el6_2.*' }
        it { is_expected.to contain 'netscape-2:8.1.2-9.el6_2.*' }
      end
    end

    if fact('os.release.major') == '7'
      describe package('yum-plugin-versionlock') do
        it { is_expected.to be_installed }
      end
    else
      describe package('python3-dnf-plugin-versionlock') do
        it { is_expected.to be_installed }
      end
    end
  end

  it 'must work if clean is specified' do
    shell('yum repolist', acceptable_exit_codes: [0])
    pp = <<-EOS
    class{yum::plugin::versionlock:
      clean => true,
    }
    # Pick an obscure package that hopefully will not be installed.
    if versioncmp($facts['os']['release']['major'],'7') <= 0 {
      yum::versionlock{ '0:samba-devel-3.1.2-9.el6_2.*':
        ensure  => present,
      }
    } else {
      yum::versionlock{'samba-devel':
        ensure  => present,
        version => '3.1.2',
        release => '9.el6_2',
      }
    }
    EOS
    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)

    # Check the cache is really empty.
    # all repos will have 0 packages.
    # bit confused by the motivation of the first test?
    if fact('os.release.major') == '7'
      shell('yum -C repolist -d0 | grep -v "repo id"  | awk "{print $NF}" FS=  | grep -v 0', acceptable_exit_codes: [1])
      shell('yum -q list available samba-devel', acceptable_exit_codes: [1])
    elsif %w[8 9].include?(fact('os.release.major'))
      shell('dnf -q list --available samba-devel', acceptable_exit_codes: [1])
    else
      shell('dnf install -y samba-devel | grep "All matches were filtered"', acceptable_exit_codes: [0])
    end
  end
end
