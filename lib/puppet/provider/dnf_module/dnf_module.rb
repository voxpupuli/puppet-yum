# frozen_string_literal: true

Puppet::Type.type(:dnf_module).provide(:dnf_module) do
  desc 'Unique provider'

  commands dnf: 'dnf'

  def get_module_state(module_name)
    dnf('-q', 'module', 'list', module_name)
  rescue Puppet::ExecutionFailure
    raise ArgumentError, "Module \"#{module_name}\" not found"
  end

  def enabled_stream
    get_module_state(resource[:module])
  end

  def enabled_stream=(stream)
    nil
  end
end
