# frozen_string_literal: true

Puppet::Type.type(:dnf_module_stream).provide(:dnf_module_stream) do
  desc 'Unique provider'

  confine package_provider: 'dnf'

  commands dnf: 'dnf'

  # Gets module default, enabled and available streams
  # Output formatted by function dnf_output_2_hash
  def streams_state(module_name)
    # This function can be called multiple times in the same resource call
    return unless @streams_current_state.nil?

    @streams_current_state = dnf('-q', 'module', 'list', module_name)
  rescue Puppet::ExecutionFailure
    # Assumes any execution error happens because module doesn't exist
    raise ArgumentError, "Module \"#{module_name}\" not found"
  end

  def stream
    nil
  end

  def stream=(target_stream)
    nil
  end
end
