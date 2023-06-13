# frozen_string_literal: true

Puppet::Type.type(:dnf_module).provide(:dnf_module) do
  desc 'Unique provider'

  def enabled_stream
    nil
  end

  def enabled_stream=(stream)
    nil
  end
end
