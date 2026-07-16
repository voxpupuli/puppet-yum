# frozen_string_literal: true

require_relative '../yumrepo_metadata_key'

# Backend parent for providers that keep keys in a per-repo GnuPG homedir (yum and dnf4).
class Puppet::Provider::YumrepoMetadataKey::GpgKeyring < Puppet::Provider::YumrepoMetadataKey
  class << self
    def fingerprints_in(home)
      ret = parse_primary_fprs(gpg_at(home, '--with-colons', '--fingerprint', '--list-keys')).uniq
      debug("fingerprints_in(#{home.inspect}) -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("fingerprints_in(#{home.inspect}) failed: #{e.message.lines.first.to_s.strip}")
      []
    end

    def export_key(home, fingerprint)
      return unless home && File.directory?(home)

      gpg_export_armored(home, fingerprint)
    end

    def store_key(home, fingerprint, text)
      Tempfile.create(['metakey', '.asc']) do |f|
        f.write(text)
        f.flush
        gpg_at(home, '--import', f.path)
        set_ultimate_trust(home, fingerprint)
      end
    end

    # --expert bypasses gpg's pre-delete check for a matching secret key.
    # That check needs gpg-agent, but --no-autostart forbids starting one,
    # so without --expert, --delete-keys fails with "no gpg-agent running".
    def remove_key(home, fingerprint)
      gpg_at(home, '--expert', '--yes', '--delete-keys', fingerprint)
    end

    def trusted?(home, fingerprint)
      ret = gpg_at(home, '--export-ownertrust').each_line.any? do |line|
        fields = line.chomp.split(':')
        fields[0].to_s.upcase == fingerprint.to_s.upcase && fields[1] == '6'
      end
      debug("trusted?(#{home.inspect}, #{fingerprint.inspect}) -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("trusted?(#{home.inspect}, #{fingerprint.inspect}) failed: #{e.message.lines.first.to_s.strip}")
      false
    end

    def set_ultimate_trust(home, fingerprint)
      Tempfile.create(['metakey-ownertrust', '.txt']) do |f|
        f.write("#{fingerprint}:6:\n")
        f.flush
        gpg_at(home, '--import-ownertrust', f.path)
      end
    end
  end
end
