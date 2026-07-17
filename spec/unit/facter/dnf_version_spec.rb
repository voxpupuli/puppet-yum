# frozen_string_literal: true

require 'spec_helper'

describe 'dnf_version fact' do
  def dnf_version(package_provider: 'dnf')
    Facter.clear
    Facter.add(:package_provider) { setcode { package_provider } }
    load File.expand_path('../../../lib/facter/dnf_version.rb', __dir__)
    Facter.value(:dnf_version)
  end

  after { Facter.clear }

  it 'is unresolved off dnf systems' do
    expect(dnf_version(package_provider: 'apt')).to be_nil
  end

  it 'is nil without dnf' do
    allow(Facter::Util::Resolution).to receive(:which).with('dnf').and_return(nil)
    expect(dnf_version).to be_nil
  end

  describe 'examples' do
    [
      {
        os: 'Fedora 43',
        command_output:
          <<~EXAMPLE,
            dnf5 version 5.2.18.0
            dnf5 plugin API version 2.0
            libdnf5 version 5.2.18.0
            libdnf5 plugin API version 2.2

            Loaded dnf5 plugins:
              name: builddep
              version: 1.0.0
              API version: 2.0

              name: changelog
              version: 1.0.0
              API version: 2.0

              name: config-manager
              version: 0.1.0
              API version: 2.0

              name: copr
              version: 0.1.0
              API version: 2.0

              name: needs_restarting
              version: 1.0.0
              API version: 2.0

              name: repoclosure
              version: 1.0.0
              API version: 2.0

              name: repomanage
              version: 1.0.0
              API version: 2.0

              name: reposync
              version: 1.0.0
              API version: 2.0
          EXAMPLE
        expected: { 'full' => '5.2.18.0', 'major' => '5' },
      },
      {
        os: 'Fedora 44',
        command_output:
          <<~EXAMPLE,
            dnf5 version 5.4.2.1
            dnf5 plugin API version 2.0
            libdnf5 version 5.4.2.1
            libdnf5 plugin API version 2.2

            Loaded dnf5 plugins:
              name: builddep
              version: 1.0.0
              API version: 2.0

              name: changelog
              version: 1.0.0
              API version: 2.0

              name: config-manager
              version: 0.1.0
              API version: 2.0

              name: copr
              version: 0.1.0
              API version: 2.0

              name: needs_restarting
              version: 1.0.0
              API version: 2.0

              name: repoclosure
              version: 1.0.0
              API version: 2.0

              name: repomanage
              version: 1.0.0
              API version: 2.0

              name: reposync
              version: 1.0.0
              API version: 2.0
          EXAMPLE
        expected: { 'full' => '5.4.2.1', 'major' => '5' },
      },
      {
        os: 'Rocky 8',
        command_output:
          <<~EXAMPLE,
            4.7.0
              Installed: dnf-0:4.7.0-20.el8.noarch at Tue May 28 13:37:11 2024
              Built    : infrastructure@rockylinux.org at Mon Oct 16 18:57:12 2023

              Installed: rpm-0:4.14.3-31.el8.x86_64 at Tue May 28 13:37:09 2024
              Built    : infrastructure@rockylinux.org at Wed Dec 13 16:45:41 2023
          EXAMPLE
        expected: { 'full' => '4.7.0', 'major' => '4' },
      },
      {
        os: 'Rocky 9',
        command_output:
          <<~EXAMPLE,
            4.14.0
              Installed: dnf-0:4.14.0-34.el9_8.rocky.0.1.noarch at Mon May 25 20:18:55 2026
              Built    : Rocky Linux Build System <releng@rockylinux.org> at Tue May 19 22:37:16 2026

              Installed: rpm-0:4.16.1.3-40.el9.x86_64 at Mon May 25 20:18:53 2026
              Built    : Rocky Linux Build System <releng@rockylinux.org> at Sun Dec 28 17:58:42 2025
          EXAMPLE
        expected: { 'full' => '4.14.0', 'major' => '4' },
      },
      {
        os: 'Rocky 10',
        command_output:
          <<~EXAMPLE,
            4.20.0
              Installed: dnf-0:4.20.0-22.el10_2.rocky.0.1.noarch at Tue May 26 00:10:06 2026
              Built    : Rocky Linux Build System <releng@rockylinux.org> at Tue May 19 14:06:23 2026

              Installed: rpm-0:4.19.1.1-23.el10.x86_64 at Tue May 26 00:10:07 2026
              Built    : Rocky Linux Build System <releng@rockylinux.org> at Sat Feb  7 14:50:19 2026
          EXAMPLE
        expected: { 'full' => '4.20.0', 'major' => '4' },
      },
    ].each do |example|
      context "with #{example[:os]} example" do
        it do
          allow(Facter::Util::Resolution).to receive(:which).with('dnf').and_return('/usr/bin/dnf')
          allow(Facter::Core::Execution).to receive(:execute).with('/usr/bin/dnf --version', on_fail: nil).and_return(example[:command_output])
          expect(dnf_version).to eq(example[:expected])
        end
      end
    end
  end
end
