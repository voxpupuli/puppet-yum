# frozen_string_literal: true

Puppet::Type.newtype(:yumrepo_metadata_key) do
  @doc = <<~DOC
    @summary Manage a GPG key in a repository's metadata keystore (repo_gpgcheck=1).

    Manage a GPG key in a repository's metadata keystore (repo_gpgcheck=1).
    Title must be "<repo>:<fingerprint>", identified by the PRIMARY fingerprint.

    On systems running `dnf` version `5`, `python3-libdnf5` must be installed before
    this type can be used.

    @example Add a key for the `updates` repository
      yumrepo_metadata_key { 'updates:3B49DF2A0F5E6E4F7A1B2C3D4E5F60718293A4B5':
        ensure  => present,
        content => file('profile/gpg_metadata_keys/updates.key'),
      }

    `repo` and `fingerprint` are derived from the title and should not be set
    independently.
  DOC

  ensurable do
    newvalue(:present) do
      @resource.provider.create
      nil
    end

    newvalue(:absent) do
      @resource.provider.destroy
      nil
    end

    defaultto :present
  end

  def self.title_patterns
    [
      [
        %r{\A(.+):(\h{40})\z}i,
        [
          [:repo, ->(x) { x }],
          [:fingerprint, ->(x) { x.delete(' ').upcase }],
        ],
      ],
    ]
  end

  newparam(:repo, namevar: true) do
    desc 'Repository id (derived from the title).'
    validate do |value|
      raise ArgumentError, 'repo must not be empty' if value.to_s.empty?
    end
  end

  newparam(:fingerprint, namevar: true) do
    desc 'Primary fingerprint (derived from the title).'
    validate do |value|
      raise ArgumentError, "fingerprint must be 40 hex characters, got #{value.inspect}" unless value.to_s.delete(' ') =~ %r{\A\h{40}\z}
    end
    munge { |value| value.to_s.delete(' ').upcase }
  end

  newparam(:name, namevar: true) do
    desc 'Composed as "<repo>:<fingerprint>".'
    defaultto ''
    munge { |value| value.to_s.empty? ? "#{resource[:repo]}:#{resource[:fingerprint]}" : value }
  end

  newproperty(:content) do
    desc 'ASCII-armored public key.'

    # Compare canonical key material, so expiry and subkey changes are detected.
    def insync?(is)
      return false if is.nil? || is == :absent

      # Force re-import if the stored key isn't trusted.
      unless provider.trusted?
        debug('content insync? -> false (key not trusted)')
        return false
      end

      current_digest = provider.class.canonical_key_digest(is)
      desired_digest = provider.class.canonical_key_digest(should)
      ret = !current_digest.nil? && current_digest == desired_digest
      debug("content insync? -> #{ret}")
      ret
    end

    # Keys are public, not secret, but full armored blocks make change notices
    # noisy and multi-line, so render concise summaries instead.
    def should_to_s(_newvalue)
      "key for #{resource[:fingerprint]}"
    end

    def is_to_s(currentvalue)
      (currentvalue == :absent) ? 'absent' : "#{currentvalue.to_s.bytesize} bytes armored"
    end
  end

  autorequire(:yumrepo) { [self[:repo]] }

  # Order after the dnf5 python binding if the catalog installs it, so the dnf5
  # provider can resolve keystore paths in the same run it is installed.
  autorequire(:package) { ['python3-libdnf5'] }
end
