# frozen_string_literal: true

Puppet::Type.newtype(:dnf_module) do
  @doc = <<-EOS
    @summary Manage DNF modules
    @param title
      Resource unique id
    @param module
      Module to be managed

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
end
