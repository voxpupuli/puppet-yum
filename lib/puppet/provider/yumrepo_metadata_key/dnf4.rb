# frozen_string_literal: true

require_relative '../yumrepo_metadata_key'

Puppet::Type.type(:yumrepo_metadata_key).provide(:dnf4, parent: Puppet::Provider::YumrepoMetadataKey) do
  desc 'dnf4/libdnf metadata keystore under /var/cache/dnf (EL8/EL9).'

  commands gpg: 'gpg', dnf: 'dnf'
  confine    'os.family': 'RedHat'
  defaultfor 'os.family': 'RedHat', 'os.release.major': %w[8 9]

  class << self
    def live_homes
      ret = repo_sources.map do |repo, source|
        [repo, File.join(cache_base, "#{repo}-#{url_hash(source)}", 'pubring')]
      end
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

    private

    def cache_base
      '/var/cache/dnf'
    end

    # Returns the path to dnf's own Python interpreter, named on its first line,
    # e.g. "#!/usr/libexec/platform-python".
    def dnf_python
      first_line = File.open(command(:dnf), &:readline)
      interpreter = first_line[%r{\A#!\s*(\S+)}, 1]
      interpreter || '/usr/bin/python3'
    rescue StandardError
      '/usr/bin/python3'
    end

    # Maps each configured repo id to the URL dnf derives its cache directory
    # from (metalink, else mirrorlist, else first baseurl, else the id itself),
    # asked of python3-dnf so we read exactly what libdnf resolved. live_homes
    # hashes this URL the same way libdnf does to locate the repo's keystore.
    def repo_sources
      script = <<~PY
        import dnf
        b = dnf.Base()
        b.read_all_repos()
        for r in b.repos.values():
            src = r.metalink or r.mirrorlist or (r.baseurl[0] if r.baseurl else r.id)
            print("%s\\t%s" % (r.id, src))
      PY
      out = Puppet::Util::Execution.execute([dnf_python, '-c', script], failonfail: true).to_s
      ret = out.each_line.filter_map do |line|
        id, src = line.chomp.split("\t", 2)
        [id, src] if id && src && !src.empty?
      end
      debug("repo_sources -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("repo_sources failed: #{e.message.lines.first.to_s.strip}")
      []
    end
  end
end
