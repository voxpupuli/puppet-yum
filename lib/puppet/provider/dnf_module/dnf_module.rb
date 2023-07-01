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
        module_hash[:default_stream] = stream if stream_string.include?('[d]')
        module_hash[:enabled_stream] = stream if stream_string.include?('[e]')
        module_hash[:streams][stream] = {profiles: [], installed_profiles: []}
        profiles_string = line[@profiles_start, @profiles_length].rstrip
        profiles_string.split(', ').each do |profile_string|
          profile = profile_string.split[0]
          module_hash[:streams][stream][:profiles] << profile
          module_hash[:streams][stream][:default_profile] = profile if profile_string.include?('[d]')
          module_hash[:streams][stream][:installed_profiles] << profile if profile_string.include?('[i]')
        end
      elsif line.split[0] == 'Name'
        @stream_start = line[/Name\s+/].length
        @stream_length = line[/Stream\s+/].length
        @profiles_start = @stream_start + @stream_length
        @profiles_length = line[/Profiles\s+/].length
      end
    end
    module_hash
  end

  def get_module_state(module_name)
    return unless @module_state.nil?
    dnf_output = dnf('-q', 'module', 'list', module_name)
  rescue Puppet::ExecutionFailure
    raise ArgumentError, "Module \"#{module_name}\" not found"
  else
    @module_state = dnf_output_2_hash(dnf_output)
    case resource[:enabled_stream]
    when false, true
      @profiles_stream = @module_state[:default_stream]
    when nil
      @profiles_stream = @module_state[:enabled_stream] || @module_state[:default_stream]
    else
      @profiles_stream = resource[:enabled_stream]
    end
  end

  def set_module_state(module_spec, action)
    dnf('-y', 'module', action, module_spec)
  end

  def validate_profiles(module_name, specified, existing)
    invalid = specified - existing
    raise ArgumentError, "Profile(s) #{invalid.map{ |profile| "\"#{profile}\""}.join(', ')} " +
      "not found in module:stream \"#{module_name}:#{@profiles_stream}\"" unless invalid.empty?
  end

  def enabled_stream
    get_module_state(resource[:module])
    raise ArgumentError, "No enabled stream to keep in module \"#{resource[:module]}\"" if
      resource[:enabled_stream].nil? and ! @module_state.key?(:enabled_stream)
    raise ArgumentError, "No default stream to enable in module \"#{resource[:module]}\"" if
      resource[:enabled_stream] == true and ! @module_state.key?(:default_stream)
    return nil if resource[:enabled_stream].nil?
    return false unless @module_state.key?(:enabled_stream)
    return true if resource[:enabled_stream] == true and
      @module_state[:enabled_stream] == @module_state[:default_stream]
    @module_state[:enabled_stream]
  end

  def enabled_stream=(stream)
    case stream
    when false
      set_module_state(resource[:module], 'reset')
    when true
      set_module_state("#{resource[:module]}:#{@module_state[:default_stream]}", 'switch-to')
    else
      set_module_state("#{resource[:module]}:#{stream}", 'switch-to')
    end
  end

  def installed_profiles
    get_module_state(resource[:module])
    if @profiles_stream.nil?
      return [] if resource[:installed_profiles].empty?
      raise ArgumentError, "No enabled or default stream in module \"#{resource[:module]}\""
    end
    stream_contents = @module_state[:streams][@profiles_stream]
    installed = stream_contents[:installed_profiles]
    if resource[:installed_profiles] == [true]
      raise ArgumentError, "No default profile to install in module:stream \"#{resource[:module]}:#{@profiles_stream}\"" unless
        stream_contents.key?(:default_profile)
      installed.include?(stream_contents[:default_profile]) ? [true] : []
    else
      validate_profiles(resource[:module], resource[:installed_profiles], stream_contents[:profiles])
      installed & resource[:installed_profiles]
    end
  end

  def installed_profiles=(profiles)
    if profiles == [true]
      set_module_state(resource[:module], 'install')
    else
      install = profiles - @module_state[:streams][@profiles_stream][:installed_profiles]
      set_module_state(install.map{ |profile| "#{resource[:module]}/#{profile}"}.join(' '), 'install')
    end
  end
end
