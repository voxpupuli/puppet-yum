# frozen_string_literal: true

require 'spec_helper'

describe 'yum_package_updates fact' do
  subject { Facter.fact(:yum_package_updates).value }

  after { Facter.clear }

  describe 'on non-Redhat distro' do
    before do
      allow(Facter.fact('os.family')).to receive(:value).and_return('Debian')
    end

    it { is_expected.to be_nil }
  end

  describe 'on Redhat distro' do
    before do
      allow(Facter.fact('os.family')).to receive(:value).and_return('Redhat')
      allow(File).to receive(:executable?) # Stub all other calls
      allow(File).to receive(:executable?).with('/usr/bin/yum').and_return(true)
      allow(Facter::Util::Resolution).to receive(:exec).with('/usr/bin/yum --assumeyes --quiet --cacheonly list updates').and_return(yum_list_updates_result)
    end

    context 'when no updates are available' do
      let(:yum_list_updates_result) { '' }

      it { is_expected.to eq([]) }
    end

    context 'when updates are available' do
      let(:yum_list_updates_result) do
        # rubocop:disable Layout/TrailingWhitespace
        <<~END
          Updated Packages
          ca-certificates.noarch  2020.2.41-70.0.el7_8     updates           
          gitlab-ce.x86_64        13.1.1-ce.0.el7          gitlab_official_ce
          grafana.x86_64          7.0.4-1                  grafana-stable    
          kernel.x86_64           3.10.0-1127.13.1.el7     updates           
          kernel-headers.x86_64   3.10.0-1127.13.1.el7     updates           
          net-snmp-libs.x86_64    1:5.7.2-48.el7_8.1       updates           
          ntp.x86_64              4.2.6p5-29.el7.centos.2  updates           
          ntpdate.x86_64          4.2.6p5-29.el7.centos.2  updates           
          passenger.x86_64        6.0.5-1.el7              passenger         
          python-perf.x86_64      3.10.0-1127.13.1.el7     updates           
          unbound.x86_64          1.6.6-5.el7_8            updates           
          unbound-libs.x86_64     1.6.6-5.el7_8            updates           
        END
        # rubocop:enable Layout/TrailingWhitespace
      end

      it do
        is_expected.to eq(%w[ca-certificates.noarch gitlab-ce.x86_64
                             grafana.x86_64 kernel.x86_64 kernel-headers.x86_64
                             net-snmp-libs.x86_64 ntp.x86_64 ntpdate.x86_64
                             passenger.x86_64 python-perf.x86_64 unbound.x86_64
                             unbound-libs.x86_64])
      end
    end

    context 'when diagnostic messages are emitted' do
      let(:yum_list_updates_result) do
        <<~END
          https://oss-binaries.phusionpassenger.com/yum/passenger/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for passenger
          Trying other mirror.
          Updated Packages
          ca-certificates.noarch  2020.2.41-70.0.el7_8     updates
        END
      end

      it { is_expected.to eq(%w[ca-certificates.noarch]) }
    end

    context 'when plugins emit output' do
      let(:yum_list_updates_result) do
        <<~END
          Loaded plugins: auto-update-debuginfo, priorities, product-id, subscription-
                        : manager, versionlock
          ca-certificates.noarch  2020.2.41-70.0.el7_8     updates
        END
      end

      it { is_expected.to eq(%w[ca-certificates.noarch]) }
    end
  end
end
