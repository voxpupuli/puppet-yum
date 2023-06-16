# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'managing a yum::group' do
  context 'installing group RPM dev tools' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::group { 'Development Tools':
        ensure => 'installed',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    # On stupid 7 test package has to be leaf package
    # to be removed with a "groupremove". Can't find
    # a common package that works.
    case fact('os.release.major')
    when '7'
      describe package('libtool') do
        it { is_expected.to be_installed }
      end
    else
      describe package('make') do
        it { is_expected.to be_installed }
      end
    end
  end

  context 'removing group RPM dev tools' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::group { 'Development Tools':
        ensure => 'absent',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    case fact('os.release.major')
    when '7'
      describe package('libtool') do
        it { is_expected.not_to be_installed }
      end
    else
      describe package('make') do
        it { is_expected.not_to be_installed }
      end
    end
  end
end
