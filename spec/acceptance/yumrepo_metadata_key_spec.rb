# frozen_string_literal: true

require 'spec_helper_acceptance'

# Install a repo's metadata-signing key, then install a package from that repo with repo_gpgcheck=1
describe 'yumrepo_metadata_key' do
  let(:signed_repos) do
    {
      'Rocky' => {
        '8' => {
          repo: 'baseos',
          baseurl: 'https://dl.rockylinux.org/vault/rocky/8.9/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial',
          fingerprint: '7051C470A929F454CEBE37B715AF5DAC6D745A60',
          package: 'zip',
        },
        '9' => {
          repo: 'baseos',
          baseurl: 'https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9',
          fingerprint: '21CB256AE16FC54C6E652949702D426D350D275D',
          package: 'zip',
        },
        '10' => {
          repo: 'baseos',
          baseurl: 'https://download.rockylinux.org/pub/rocky/10/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-10',
          fingerprint: 'FC226859C0860BF0DDB95B085B106C736FEDFC85',
          package: 'zip',
        },
      },
      'AlmaLinux' => {
        '8' => {
          repo: 'baseos',
          baseurl: 'https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux',
          key_index: 1, # this file bundles two keys; the signer is the second
          fingerprint: 'BC5EDDCADF502C077F1582882AE81E8ACED7258B',
          package: 'zip',
        },
        '9' => {
          repo: 'baseos',
          baseurl: 'https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux-9',
          fingerprint: 'BF18AC2876178908D6E71267D36CB86CB86B3716',
          package: 'zip',
        },
      },
      'CentOS' => {
        '9' => {
          repo: 'baseos',
          baseurl: 'https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/',
          keyfile: '/etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial',
          fingerprint: '99DB70FAE1D7CE227FB6488205B555B38483C65D',
          package: 'zip',
        },
      },
      # Oracle Linux does not sign its base metadata, so test against a signed third-party repo (Docker CE) instead.
      'OracleLinux' => {
        '8' => {
          repo: 'docker',
          baseurl: 'https://download.docker.com/linux/centos/8/x86_64/stable/',
          key_url: 'https://download.docker.com/linux/centos/gpg',
          fingerprint: '060A61C51B558A7F742B77AAC52FEB6B621E9F35',
          package: 'docker-compose-plugin',
        },
        '9' => {
          repo: 'docker',
          baseurl: 'https://download.docker.com/linux/centos/9/x86_64/stable/',
          key_url: 'https://download.docker.com/linux/centos/gpg',
          fingerprint: '060A61C51B558A7F742B77AAC52FEB6B621E9F35',
          package: 'docker-compose-plugin',
        },
      },
    }
  end

  it 'installs a repo metadata-signing key and verifies signed metadata end to end' do
    os_name = fact('os.name')
    major = fact('os.release.major')
    repo = signed_repos.dig(os_name, major)
    skip "no known signed repo for #{os_name} #{major}" unless repo

    title = "#{repo[:repo]}:#{repo[:fingerprint]}"

    keyfile = repo[:keyfile]
    if repo[:key_url]
      keyfile = '/tmp/yumrepo_metadata_key_acceptance.asc'
      shell("curl -sfL '#{repo[:key_url]}' -o #{keyfile}")
    end

    shell("dnf remove -y #{repo[:package]} || true")
    shell('dnf clean all')

    pp = <<~PUPPET
      # Purge stock repos so the cache dir (and keystore path) is deterministic.
      resources { 'yumrepo':
        purge  => true,
        before => Package[#{repo[:package]}],
      }

      # Some keyfiles bundle several keys; keep only the block we manage.
      $blocks = split(file('#{keyfile}'), /(?=-----BEGIN PGP PUBLIC KEY BLOCK-----)/).filter |$b| { $b =~ /BEGIN PGP/ }

      # Declared first on purpose: autorequire must still order it after the repo.
      yumrepo_metadata_key { '#{title}':
        ensure  => present,
        content => $blocks[#{repo.fetch(:key_index, 0)}],
      }

      yumrepo { '#{repo[:repo]}':
        descr         => '#{repo[:repo]} (acceptance test)',
        baseurl       => '#{repo[:baseurl]}',
        enabled       => 1,
        repo_gpgcheck => 1, # verified only against the keystore our type fills
        gpgcheck      => 0, # package sigs out of scope
      }

      package { '#{repo[:package]}':
        ensure  => installed,
        require => Yumrepo_metadata_key['#{title}'],
      }
    PUPPET

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)

    keys = shell(%(for h in /var/cache/dnf/#{repo[:repo]}-*/pubring; do gpg --homedir "$h" --list-keys --with-colons; done)).stdout
    expect(keys).to match(repo[:fingerprint])
    expect(shell("rpm -q #{repo[:package]}", acceptable_exit_codes: [0, 1]).exit_code).to eq(0)
  end
end
