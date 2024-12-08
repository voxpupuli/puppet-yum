# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum::copr' do
  context 'when @caddy/caddy and copart/restic are enabled' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-PUPPET
      yum::copr { ['@caddy/caddy', 'copart/restic']: }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    describe command('dnf copr list') do
      its(:stdout) { is_expected.to match(%r{^copr.fedorainfracloud.org/copart/restic$}) }
      its(:stdout) { is_expected.to match(%r{^copr.fedorainfracloud.org/group_caddy/caddy$}) }
    end
  end

  context 'when copart/restic is disabled' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-PUPPET
      yum::copr { ['@caddy/caddy', 'copart/restic']:
        ensure => 'disabled',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    describe command('dnf copr list') do
      its(:stdout) { is_expected.to match(%r{^copr.fedorainfracloud.org/copart/restic \(disabled\)$}) }
      its(:stdout) { is_expected.to match(%r{^copr.fedorainfracloud.org/group_caddy/caddy \(disabled\)$}) }
    end
  end

  context 'when copart/restic is removed' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-PUPPET
      yum::copr { ['@caddy/caddy', 'copart/restic']:
        ensure => 'removed',
      }
      PUPPET

      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end

    describe command('dnf copr list') do
      its(:stdout) { is_expected.not_to match(%r{^copr.fedorainfracloud.org/copart/restic$}) }
      its(:stdout) { is_expected.not_to match(%r{^copr.fedorainfracloud.org/group_caddy/caddy$}) }
    end
  end
end
