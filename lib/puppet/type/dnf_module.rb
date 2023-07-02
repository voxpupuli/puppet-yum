# frozen_string_literal: true

Puppet::Type.newtype(:dnf_module) do
  @doc = <<-EOS
    @summary Manage DNF modules
    @example Install MariaDB 10.5 Galera profile
      dnf_module { 'mariadb_galera_10.5':
        module             => 'mariadb',
        enabled_stream     => '10.5',
        installed_profiles => 'galera',
        removed_profiles   => true,
      }
    @param title
      Resource unique id
    @param module
      Module to be managed
    @param enabled_stream
      Module stream to be enabled
    @param installed_profiles
      Module profile(s) to be installed
    @param removed_profiles
      Module profile(s) to be removed

    This type allows Puppet to enable/disable streams and install/remove profiles via DNF modules
EOS

  newparam(:title, namevar: true) do
    desc 'Resource title'
  end

  newparam(:module) do
    desc 'Module to be managed (String)'
    validate do |value|
      Puppet.debug { "Module: \"#{value}\"" }
      raise TypeError, 'Module name should be a string' unless value.is_a?(String)
    end
  end

  newproperty(:enabled_stream) do
    desc <<-EOS
      Module stream that should be enabled
        String - Specify stream
        true - Default stream
        false - No stream (resets module)
        nil (default) - Keep current
    EOS
    validate do |value|
      raise TypeError, 'Module stream should be a string, true, false or undef' unless
        [true, false, nil].include?(value) or value.is_a?(String)
    end
    def insync?(is)
      Puppet.debug { "enabled_stream - is: \"#{is}\" - should: \"#{should}\"" }
      is == should
    end
  end

  newproperty(:installed_profiles, :array_matching => :all) do
    desc <<-EOS
      Module profile(s) that should be installed
        String or Array - Specify profile(s)
        true - Default profile
    EOS
    defaultto []
    validate do |value|
      raise TypeError, 'Module profiles should be a string, an array of strings or true' unless
        value == true or value.is_a?(String)
    end
    # Ignore profiles order if user provided a list
    def insync?(is)
      Puppet.debug { "installed_profiles - is: \"#{is}\" - should: \"#{should}\"" }
      is.is_a?(Array) ? is.sort == should.sort : is == should
    end
  end

  newproperty(:removed_profiles, :array_matching => :all) do
    desc <<-EOS
      Module profile(s) that should be removed
        String or Array - Specify profile(s)
        true - All not listed in installed_profiles
    EOS
    defaultto []
    validate do |value|
      raise TypeError, 'Module profiles should be a string, an array of strings or true' unless
        value == true or value.is_a?(String)
    end
    # Ignore profiles order if user provided a list
    def insync?(is)
      Puppet.debug { "removed_profiles - is: \"#{is}\" - should: \"#{should}\"" }
      is.is_a?(Array) ? is.sort == should.sort : is == should
    end
  end
end
