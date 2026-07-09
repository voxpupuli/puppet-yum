# frozen_string_literal: true

require_relative '../yumrepo_metadata_key'

Puppet::Type.type(:yumrepo_metadata_key).provide(:yum, parent: Puppet::Provider::YumrepoMetadataKey) do
  desc 'yum-3 per-repo gpgdir (EL7).'

  commands gpg: 'gpg', yum: 'yum'
  confine    'os.family': 'RedHat'
  defaultfor 'os.family': 'RedHat', 'os.release.major': '7'

  class << self
    def live_homes
      ret = gpgdirs.map { |home| [File.basename(File.dirname(home)), home] }
      debug("live_homes -> #{ret.inspect}")
      ret
    end

    def all_homes_for(repo)
      ret = gpgdirs.select { |home| File.basename(File.dirname(home)) == repo }
      debug("all_homes_for(#{repo.inspect}) -> #{ret.inspect}")
      ret
    end

    # EL7's gpg predates --no-autostart, so drop it from the parent's flags.
    def gpg_common_flags
      super - ['--no-autostart']
    end

    def show_keys_args(path)
      ['--with-colons', '--with-fingerprint', path]
    end

    private

    # yum keeps per-repo gpgdirs under both /var/lib/yum (persistent state) and
    # /var/cache/yum (cache); a repo's keystore can appear in either, so scan both.
    def gpgdirs
      ret = Dir.glob('/var/lib/yum/repos/*/*/*/gpgdir') + Dir.glob('/var/cache/yum/*/*/*/gpgdir')
      debug("gpgdirs -> #{ret.inspect}")
      ret
    end
  end
end
