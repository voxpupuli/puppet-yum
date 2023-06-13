# frozen_string_literal: true

Puppet::Type.type(:dnf_module).provide(:dnf_module) do
  desc 'Unique provider'

  commands dnf: 'dnf'

  def dnf_output_2_hash(dnf_output)
    module_hash = {streams: {}}
    dnf_output.lines.each do |line|
      line.chomp!
      break if line.empty?
      if ! @stream_start.nil?
        stream_string = line[@stream_start, @stream_length].rstrip
        stream = stream_string.split[0]
        module_hash[:streams][stream] = {}
      elsif line.split[0] == 'Name'
        @stream_start = line[/Name\s+/].length
        @stream_length = line[/Stream\s+/].length
      end
    end
    module_hash
  end

  def get_module_state(module_name)
    dnf_output = dnf('-q', 'module', 'list', module_name)
  rescue Puppet::ExecutionFailure
    raise ArgumentError, "Module \"#{module_name}\" not found"
  else
    @module_state = dnf_output_2_hash(dnf_output)
  end

  def enabled_stream
    get_module_state(resource[:module])
  end

  def enabled_stream=(stream)
    nil
  end
end
