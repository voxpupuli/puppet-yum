# frozen_string_literal: true

Puppet::Type.newtype(:dnf_module) do
  @doc = <<-EOS
    @summary Manage DNF modules

    This type allows Puppet to enable/disable streams and install/remove profiles via DNF modules
EOS
end
