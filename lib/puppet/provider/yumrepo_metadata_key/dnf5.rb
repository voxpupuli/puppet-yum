# frozen_string_literal: true

require_relative '../yumrepo_metadata_key'

Puppet::Type.type(:yumrepo_metadata_key).provide(:dnf5, parent: Puppet::Provider::YumrepoMetadataKey) do
  desc 'dnf5/libdnf5 metadata keystore under /var/cache/libdnf5 (Fedora 43+, EL11+).'

  commands gpg: 'gpg', dnf: 'dnf'
  confine    package_provider: 'dnf'
  confine    'dnf_version.major': '5'
  confine    feature: :libdnf5
  defaultfor package_provider: 'dnf'

  # dnf5 stores each key as an armored <LONGKEYID>.pub file, looked up by that
  # exact filename. No GnuPG keyring or ownertrust; a present file is trusted.
  class << self
    def live_homes
      ret = repo_cachedirs.map { |repo, cachedir| [repo, File.join(cachedir, 'pubring')] }
      debug("live_homes -> #{ret.inspect}")
      ret
    end

    def all_homes_for(repo)
      ret = Dir.glob(File.join(cache_base, "#{repo}-*", 'pubring')).select do |home|
        File.basename(File.dirname(home)) =~ %r{\A#{Regexp.escape(repo)}-\h{16}\z} && File.directory?(home)
      end
      debug("all_homes_for(#{repo.inspect}) -> #{ret.inspect}")
      ret
    end

    def fingerprints_in(home)
      ret = Dir.glob(File.join(home, '*.pub')).filter_map { |file| primary_fpr_of_content(File.read(file)) }.uniq
      debug("fingerprints_in(#{home.inspect}) -> #{ret.inspect}")
      ret
    end

    def export_key(home, fingerprint)
      return unless home && File.directory?(home)

      file = pub_file(home, fingerprint)
      File.file?(file) ? File.read(file) : nil
    end

    def store_key(home, fingerprint, text)
      file = pub_file(home, fingerprint)
      File.write(file, extract_armored_key(text, "content for #{fingerprint}") || text)
      debug("store_key #{fingerprint} -> #{file.inspect}")
    end

    def remove_key(home, fingerprint)
      file = pub_file(home, fingerprint)
      File.delete(file) if File.file?(file)
    end

    def trusted?(_home, _fingerprint)
      true
    end

    private

    def pub_file(home, fingerprint)
      File.join(home, "#{long_keyid(fingerprint)}.pub")
    end

    def long_keyid(fingerprint)
      fingerprint.to_s.delete(' ').upcase[-16, 16]
    end

    def cache_base
      '/var/cache/libdnf5'
    end

    # Ask libdnf5 for each configured repo's resolved cache directory. get_cachedir
    # already encodes the base dir and the per-repo hash, so live_homes points at
    # exactly the directory dnf5 will populate, even before it has been created.
    def repo_cachedirs
      script = <<~PY
        import libdnf5
        base = libdnf5.base.Base()
        base.load_config()
        base.setup()
        sack = base.get_repo_sack()
        sack.create_repos_from_system_configuration()
        for repo in libdnf5.repo.RepoQuery(base):
            print("%s\\t%s" % (repo.get_id(), repo.get_cachedir()))
      PY
      out = Puppet::Util::Execution.execute(['python3', '-c', script], failonfail: true).to_s
      ret = out.each_line.filter_map do |line|
        id, dir = line.chomp.split("\t", 2)
        [id, dir] if id && dir && !dir.empty?
      end
      debug("repo_cachedirs -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("repo_cachedirs failed: #{e.message.lines.first.to_s.strip}")
      []
    end
  end
end
