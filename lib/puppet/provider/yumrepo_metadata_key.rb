# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'tempfile'
require 'tmpdir'

class Puppet::Provider::YumrepoMetadataKey < Puppet::Provider
  class << self
    # Concrete providers must implement these to locate a repo's keystore(s):
    #   live_homes       -> [[repo, home], ...] for the current 'live' keystores
    #   all_homes_for    -> [home, ...] every keystore for repo (destroy sweep)
    def live_homes
      raise NotImplementedError, "#{self} must implement .live_homes"
    end

    def all_homes_for(_repo)
      raise NotImplementedError, "#{self} must implement .all_homes_for"
    end

    def instances
      ret = live_homes.flat_map do |repo, home|
        next [] unless File.directory?(home) # home may not exist yet if dnf hasn't populated the cache for this repo

        primary_fingerprints_in(home).map do |fpr|
          new(ensure: :present, name: "#{repo}:#{fpr}", repo: repo, fingerprint: fpr,
              home: home, content: export_key(home, fpr))
        end
      end
      debug("instances -> #{ret.map(&:name).inspect}")
      ret
    end

    def prefetch(resources)
      instances.each do |prov|
        res = resources[prov.name]
        res.provider = prov if res
      end
    end

    def primary_fingerprints_in(home)
      ret = parse_primary_fprs(gpg_at(home, '--with-colons', '--fingerprint', '--list-keys')).uniq
      debug("primary_fingerprints_in(#{home.inspect}) -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("primary_fingerprints_in(#{home.inspect}) failed: #{e.message.lines.first.to_s.strip}")
      []
    end

    # gpg --with-colons emits a `pub:` record for each primary key immediately
    # followed by its `fpr:` record (fingerprint in field 10). Pair adjacent
    # records and keep the fpr after each `pub:`, ignoring `sub:` (subkey) fprs.
    def parse_primary_fprs(text)
      text.lines.map { |line| line.split(':') }.each_cons(2).filter_map do |record, next_record|
        next_record[9] if record[0] == 'pub' && next_record[0] == 'fpr'
      end
    end

    def extract_armored_key(text, context)
      match = text.to_s.match(%r{-----BEGIN PGP PUBLIC KEY BLOCK-----.*?-----END PGP PUBLIC KEY BLOCK-----}m)
      unless match
        warning("#{context} did not contain an armored public key: #{text.to_s.lines.first.to_s.strip}") unless text.to_s.strip.empty?
        return nil
      end

      extra = text.to_s.sub(match[0], '').strip
      warning("#{context} included unexpected output: #{extra.lines.first.to_s.strip}") unless extra.empty?
      "#{match[0]}\n"
    end

    # Armored public key for `fingerprint` from the keystore at `home`, or
    # nil if the home is missing or the key can't be exported.
    def export_key(home, fingerprint)
      return unless home && File.directory?(home)

      out =
        begin
          gpg_at(home, '--export', '--armor', fingerprint)
        rescue Puppet::ExecutionFailure
          ''
        end
      extract_armored_key(out, "gpg export for #{fingerprint}")
    end

    # Canonicalise a key so semantically-equal keys hash equally: import `text`
    # into a throwaway keyring, re-export it --armor, and SHA256 the result.
    # This normalises armor formatting/packet ordering and captures expiry and
    # subkey changes that a raw compare of the supplied ASCII would miss.
    def canonical_key_digest(text)
      ret = Dir.mktmpdir do |tmp|
        keyfile = File.join(tmp, 'k.asc')
        File.write(keyfile, text)
        gpg_at(tmp, '--import', keyfile)
        primary = parse_primary_fprs(gpg_at(tmp, '--with-colons', '--fingerprint', '--list-keys')).first
        exported = primary && export_key(tmp, primary)
        exported ? Digest::SHA256.hexdigest(exported) : nil
      rescue Puppet::ExecutionFailure => e
        debug("canonical_key_digest failed: #{e.message.lines.first.to_s.strip}")
        nil
      end
      debug("canonical_key_digest -> #{ret.inspect}")
      ret
    end

    def primary_fpr_of_content(text)
      ret = Dir.mktmpdir do |tmp|
        keyfile = File.join(tmp, 'k.asc')
        File.write(keyfile, text)
        parse_primary_fprs(gpg_at(tmp, *show_keys_args(keyfile))).first
      end
      debug("primary_fpr_of_content -> #{ret.inspect}")
      ret
    end

    def ultimate_trust?(home, fingerprint)
      ret = gpg_at(home, '--export-ownertrust').each_line.any? do |line|
        fields = line.chomp.split(':')
        fields[0].to_s.upcase == fingerprint.to_s.upcase && fields[1] == '6'
      end
      debug("ultimate_trust?(#{home.inspect}, #{fingerprint.inspect}) -> #{ret.inspect}")
      ret
    rescue Puppet::ExecutionFailure => e
      debug("ultimate_trust?(#{home.inspect}, #{fingerprint.inspect}) failed: #{e.message.lines.first.to_s.strip}")
      false
    end

    def set_ultimate_trust(home, fingerprint)
      Tempfile.create(['metakey-ownertrust', '.txt']) do |f|
        f.write("#{fingerprint}:6:\n")
        f.flush
        gpg_at(home, '--import-ownertrust', f.path)
      end
    end

    def url_hash(source)
      Digest::SHA256.digest(source)[0, 8].unpack1('H*')
    end

    def gpg_at(home, *args)
      gpg('--homedir', home, *gpg_common_flags, *args)
    end

    def gpg_common_flags
      ['--batch', '--no-tty', '--no-autostart', '--no-permission-warning']
    end

    def show_keys_args(path)
      ['--with-colons', '--show-keys', path]
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    import_key(resource[:content])
    @property_hash[:ensure] = :present
  end

  # Deletes the key not only in the 'live' keystore, but also in any others than might exist (from eg. when the baseurl for a repo was different)
  def destroy
    homes = self.class.all_homes_for(resource[:repo])
    debug("destroy sweeping #{resource[:fingerprint]} across #{homes.inspect}")
    homes.each do |home|
      next unless File.directory?(home)

      begin
        # --expert bypasses gpg's pre-delete check for a matching secret key.
        # That check needs gpg-agent, but --no-autostart forbids starting one,
        # so without --expert, --delete-keys fails with "no gpg-agent running".
        self.class.gpg_at(home, '--expert', '--yes', '--delete-keys', resource[:fingerprint])
        debug("destroy removed #{resource[:fingerprint]} from #{home.inspect}")
      rescue Puppet::ExecutionFailure => e
        debug("destroy skipped #{home.inspect}: #{e.message.lines.first.to_s.strip}")
      end
    end
    @property_hash[:ensure] = :absent
  end

  def content
    @property_hash[:content] || :absent
  end

  def content=(value)
    debug("content= re-importing #{resource[:fingerprint]}")
    import_key(value)
  end

  def ultimate_trust?
    home = live_home
    home && self.class.ultimate_trust?(home, resource[:fingerprint])
  end

  # NOTE: mk_resource_methods can't be used here. It needs a type-bound
  # provider (this abstract parent has resource_type == nil), and running it in
  # the concrete providers would regenerate a `content=` that just writes
  # @property_hash, clobbering our importing content= below. These trivial
  # getters are the mk_resource_methods equivalent, written by hand.
  def repo
    @property_hash[:repo]
  end

  def fingerprint
    @property_hash[:fingerprint]
  end

  private

  def import_key(text)
    raise Puppet::Error, 'content is required when ensure => present' if text.nil? || text == :absent

    dir = live_home
    raise Puppet::Error, "cannot locate live keystore for repo '#{resource[:repo]}'" unless dir

    Tempfile.create(['metakey', '.asc']) do |f|
      f.write(text)
      f.flush

      primary = self.class.primary_fpr_of_content(text)
      raise Puppet::Error, "fingerprint #{resource[:fingerprint]} is not the primary of the supplied key (primary is #{primary})" if primary && primary != resource[:fingerprint]

      FileUtils.mkdir_p(dir, mode: 0o700)
      debug("import_key #{resource[:fingerprint]} -> #{dir.inspect}")
      self.class.gpg_at(dir, '--import', f.path)
      self.class.set_ultimate_trust(dir, resource[:fingerprint])
    end
  end

  def live_home
    @live_home ||= @property_hash[:home] || self.class.live_homes.to_h[resource[:repo]]
  end
end
