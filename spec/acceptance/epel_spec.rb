# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'yum class with EPEL', if: !%w[Fedora Amazon].include?(fact('os.name')) do
  it_behaves_like 'an idempotent resource' do
    let(:manifest) do
      <<-PUPPET
      class { 'yum':
        managed_repos => ['epel'],
      }
      PUPPET
    end
  end

  # certbot's dependencies are built against the base OS, so this fails if EPEL serves a mismatched branch.
  describe command('dnf -y install --downloadonly certbot') do
    its(:exit_status) { is_expected.to eq 0 }
  end
end
