# frozen_string_literal: true

Puppet::Type.newtype(:dnf_module) do
  @doc = <<-EOS
    @summary Manage DNF modules
    @example Enable MariaDB 10.5 stream
      dnf_module { 'mariadb_10.5':
        module         => 'mariadb',
        enabled_stream => '10.5',
      }
    @param title
      Resource unique id
    @param module
      Module to be managed
    @param enabled_stream
      Module stream to be enabled

    This type allows Puppet to enable/disable streams and install/remove profiles via DNF modules
EOS

  newparam(:title, namevar: true) do
    desc 'Resource title'
  end

  newparam(:module) do
    desc 'Module to be managed (String)'
    validate do |value|
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
  end

end
