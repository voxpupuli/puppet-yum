# frozen_string_literal: true

Puppet::Type.type(:dnf_module).provide(:dnf_module) do
  desc 'Unique provider'

  confine package_provider: 'dnf'

  commands dnf: 'dnf'

  # Converts plain output from 'dnf module list <Module>' to an array formatted as:
  # {
  #   default_stream: "<Default stream> (if there's one)",
  #   enabled_stream: "<Enabled stream> (if there's one)",
  #   streams: {
  #     "<Stream>" => {
  #       profiles: [<All available profiles for the stream>],
  #       default_profile: "<Default profile> (if there's one)",
  #       installed_profiles: [<All currently installed profiles>],
  #     }
  #   },
  #   "<Stream>" => {...},
  #   ...,
  # }
  def dnf_output_2_hash(dnf_output)
    module_hash = {streams: {}}
    dnf_output.lines.each do |line|
      line.chomp!
      break if line.empty?
      # @stream_start, @stream_length, @profiles_start and @profiles_length:
      # chunk of dnf output line with stream or profile info
      # Determined in elsif block below from dnf output header
      if ! @stream_start.nil?
        # Stream string is '<Stream>', '<Stream> [d][e]', or the like
        stream_string = line[@stream_start, @stream_length].rstrip
        stream = stream_string.split[0]
        module_hash[:default_stream] = stream if stream_string.include?('[d]')
        module_hash[:enabled_stream] = stream if stream_string.include?('[e]')
        module_hash[:streams][stream] = {profiles: [], installed_profiles: []}
        profiles_string = line[@profiles_start, @profiles_length].rstrip
        profiles_string.split(', ').each do |profile_string|
          # Profile string is '<Profile>', '<Profile> [d][i]', or the like
          profile = profile_string.split[0]
          module_hash[:streams][stream][:profiles] << profile
          module_hash[:streams][stream][:default_profile] = profile if profile_string.include?('[d]')
          module_hash[:streams][stream][:installed_profiles] << profile if profile_string.include?('[i]')
        end
      elsif line.split[0] == 'Name'
        # 'dnf module list' output header is 'Name<Spaces>Stream<Spaces>Profiles<Spaces>...'
        # Each field has same position of data that follows
        @stream_start = line[/Name\s+/].length
        @stream_length = line[/Stream\s+/].length
        @profiles_start = @stream_start + @stream_length
        @profiles_length = line[/Profiles\s+/].length
      end
    end
    module_hash
  end

  # Gets current state of stream and profiles of specified module
  # Output formatted by function dnf_output_2_hash
  def get_module_state(module_name)
    # This function can be called multiple times in the same resource call
    return unless @module_state.nil?
    dnf_output = dnf('-q', 'module', 'list', module_name)
  rescue Puppet::ExecutionFailure
    # Assumes any execution error happens because module doesn't exist
    raise ArgumentError, "Module \"#{module_name}\" not found"
  else
    @module_state = dnf_output_2_hash(dnf_output)
    # Which stream to use in functions which manage profiles
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

  # Checks if all specified profiles exist in module's stream
  def validate_profiles(module_name, specified, existing)
    return unless specified.is_a?(Array)
    invalid = specified - existing
    raise ArgumentError, "Profile(s) #{invalid.map{ |profile| "\"#{profile}\""}.join(', ')} " +
      "not found in module:stream \"#{module_name}:#{@profiles_stream}\"" unless invalid.empty?
  end

  def enabled_stream
    get_module_state(resource[:module])
    case resource[:enabled_stream]
    when nil    # Nothing to do
      nil
    when false  # Act if any stream is enabled
      # Doesn't call setter, even if statement below returns true. Might be bug.
      @module_state.key?(:enabled_stream)
    when true   # Act if default stream isn't enabled
      # Specified stream = true requires an existing default stream
      raise ArgumentError, "No default stream to enable in module \"#{resource[:module]}\"" unless
        @module_state.key?(:default_stream)
      @module_state[:enabled_stream] == @module_state[:default_stream]
    else        # Act if specified stream isn't enabled
      @module_state[:enabled_stream]
    end
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
    # Profiles exist inside stream
    if @profiles_stream.nil?
      # Used by function removed_profiles
      @profiles_to_install = []
      return [] if resource[:installed_profiles].empty?
      raise ArgumentError, "No enabled or default stream in module \"#{resource[:module]}\""
    end
    stream_contents = @module_state[:streams][@profiles_stream]
    installed = stream_contents[:installed_profiles]
    if resource[:installed_profiles] == [true]
      # Specified profile = true requires an existing default profile
      raise ArgumentError, "No default profile to install in module:stream \"#{resource[:module]}:#{@profiles_stream}\"" unless
        stream_contents.key?(:default_profile)
      # Used by function removed_profiles
      @profiles_to_install = stream_contents[:default_profile]
      # Act if default profile isn't installed
      installed.include?(stream_contents[:default_profile]) ? [true] : []
    else
      validate_profiles(resource[:module], resource[:installed_profiles], stream_contents[:profiles])
      # Used by function removed_profiles
      @profiles_to_install = resource[:installed_profiles]
      # Only installed profiles included in specified ones are relevant here
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

  def removed_profiles
    return resource[:removed_profiles] if resource[:removed_profiles].nil? or resource[:removed_profiles].empty?
    get_module_state(resource[:module])
    stream_contents = @module_state[:streams][@profiles_stream]
    # Profiles exist inside stream
    raise ArgumentError, "No enabled or default stream in module \"#{resource[:module]}\"" if
      @profiles_stream.nil?
    if resource[:removed_profiles] == [true]
      # Act if any currently installed profiles aren't in specified ones
      @profiles_to_remove = stream_contents[:installed_profiles] - @profiles_to_install
      @profiles_to_remove.empty? ? [true] : []
    else
      conflicting = @profiles_to_install & resource[:removed_profiles]
      raise ArgumentError, "Profile(s) #{conflicting}.join(', ') listed to both install and remove " +
        "in module \"#{resource[:module]}\"" unless conflicting.empty?
      validate_profiles(resource[:module], resource[:removed_profiles], stream_contents[:profiles])
      # Installed profiles become missing from removed list and cause action
      @profiles_to_remove = resource[:removed_profiles] & stream_contents[:installed_profiles]
      resource[:removed_profiles] - stream_contents[:installed_profiles]
    end
  end

  def removed_profiles=(profiles)
    dnf('-y', 'module', 'remove', @profiles_to_remove.map{ |profile| "#{resource[:module]}/#{profile}"}.join(' '))
  end
end
