# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'dnf_version fact' do
  it 'runs dnf --version' do
    version = shell('dnf --version')
    logger.info(version.stdout)
    expect(version.stdout).not_to be_empty
  end

  it 'reports the installed major version' do
    major = shell(%q(dnf --version | grep -oE '[0-9]+(\.[0-9]+)+' | head -1 | cut -d. -f1)).stdout.strip

    pp = <<~PUPPET
      $dnf_major_version = $facts['dnf_version']['major']
      if $dnf_major_version == '#{major}' {
        notify { "dnf_version.major=${facts['dnf_version']['major']}": }
      } else {
        fail("dnf_major_version ${dnf_major_version} didn't match expected version '#{major}'")
      }
    PUPPET

    result = apply_manifest(pp, catch_failures: true)

    expect(result.stdout).to match(%r{dnf_version\.major=#{major}\b})
  end
end
